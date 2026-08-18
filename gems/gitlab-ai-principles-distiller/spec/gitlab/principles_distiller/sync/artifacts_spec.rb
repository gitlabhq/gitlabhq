# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../support/tmpdir'
require_relative '../../../../lib/gitlab/principles_distiller/sync'

RSpec.describe Gitlab::PrinciplesDistiller::Sync::Artifacts do
  include TmpdirHelper

  let(:tmpdir) { mktmpdir }
  let(:dir) { File.join(tmpdir, 'tmp/ai-principles-distilled') }
  let(:artifacts) { described_class.new(dir) }

  before do
    Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
  end

  describe '#write' do
    subject(:write) { artifacts.write('qa', status, content: content) }

    let(:content) { 'distilled body' }

    context 'when the principle was updated' do
      let(:status) { described_class::STATUS_UPDATED }

      it 'writes both the status and the content', :aggregate_failures do
        write

        expect(File.read(File.join(dir, 'qa.status'))).to eq(described_class::STATUS_UPDATED)
        expect(File.read(File.join(dir, 'qa.md'))).to eq('distilled body')
      end
    end

    # An unchanged or failed principle has no body to publish, so writing a content file for it would let the collect
    # job pick up stale content from an earlier run's artifact.
    # The content is passed deliberately here to prove it is ignored rather than merely absent.
    context 'when the principle was not updated' do
      let(:status) { described_class::STATUS_UNCHANGED }
      let(:content) { 'ignored' }

      it 'writes only the status', :aggregate_failures do
        write

        expect(File.read(File.join(dir, 'qa.status'))).to eq(described_class::STATUS_UNCHANGED)
        expect(File.exist?(File.join(dir, 'qa.md'))).to be(false)
      end
    end

    context 'when the artifact directory does not exist' do
      let(:status) { described_class::STATUS_FAILED }

      it 'creates it' do
        expect { write }.to change { Dir.exist?(dir) }.from(false).to(true)
      end
    end
  end

  describe '#collect' do
    subject(:collected) { artifacts.collect(expected) }

    let(:expected) { %w[alpha beta gamma] }

    # In CI the directory always exists by the time collect runs (the distill jobs' artifacts are extracted into it), so
    # create it up front rather than relying on #write to do it.
    before do
      FileUtils.mkdir_p(dir)
    end

    context 'when every principle reported an outcome' do
      before do
        artifacts.write('alpha', described_class::STATUS_UPDATED, content: 'alpha body')
        artifacts.write('beta', described_class::STATUS_UNCHANGED)
        artifacts.write('gamma', described_class::STATUS_FAILED)
      end

      it 'sorts each principle into its own state' do
        expect(collected).to eq(
          described_class::Collected.new(contents: { 'alpha' => 'alpha body' }, failed: ['gamma'], not_run: [])
        )
      end
    end

    # The core distinction this artifact contract exists for: a principle whose job never ran has not been shown to be
    # undistillable, so reporting it as a distillation failure would send an operator chasing a defect that does not
    # exist (see gitlab-org/gitlab#607365).
    context 'when a principle produced no artifact at all' do
      before do
        artifacts.write('alpha', described_class::STATUS_UPDATED, content: 'alpha body')
        artifacts.write('gamma', described_class::STATUS_FAILED)
      end

      it 'reports it as not run rather than failed' do
        expect(collected).to eq(
          described_class::Collected.new(contents: { 'alpha' => 'alpha body' }, failed: ['gamma'], not_run: ['beta'])
        )
      end
    end

    # An `updated` status with no "body" is a truncated artifact upload, i.e. an infrastructure problem.
    # Publishing an empty distilled file would wipe the principle's committed content, so it degrades to not_run and is
    # re-attempted next run.
    context 'when a principle is updated but its content artifact is missing' do
      let(:expected) { ['alpha'] }

      before do
        File.write(File.join(dir, 'alpha.status'), described_class::STATUS_UPDATED)
      end

      it 'warns and reports it as not run', :aggregate_failures do
        expect { collected }.to output(/content artifact is missing or empty/).to_stderr

        expect(collected).to eq(described_class::Collected.new(contents: {}, failed: [], not_run: ['alpha']))
      end
    end

    context 'when a status artifact holds an unrecognised value' do
      let(:expected) { ['alpha'] }

      before do
        File.write(File.join(dir, 'alpha.status'), 'something-else')
      end

      it 'reports it as not run rather than failed' do
        expect(collected).to eq(described_class::Collected.new(contents: {}, failed: [], not_run: ['alpha']))
      end
    end

    # The publish step groups by owning team and renders principle lists into commit messages and MR descriptions, so
    # the order has to come from the expected list rather than from whichever job finished first.
    context 'when the artifacts were written out of order' do
      before do
        artifacts.write('gamma', described_class::STATUS_UPDATED, content: 'gamma body')
        artifacts.write('alpha', described_class::STATUS_UPDATED, content: 'alpha body')
        artifacts.write('beta', described_class::STATUS_UPDATED, content: 'beta body')
      end

      it 'returns contents in the expected order' do
        expect(collected.contents.keys).to eq(%w[alpha beta gamma])
      end
    end

    context 'when nothing was expected' do
      let(:expected) { [] }

      it 'returns an empty result' do
        expect(collected).to eq(described_class::Collected.new(contents: {}, failed: [], not_run: []))
      end
    end
  end

  # Principle names reach the artifact layer through a CI variable, so they get the same traversal guard as every other
  # workspace-derived path.
  describe 'path traversal' do
    it 'rejects a principle name that escapes the artifact directory' do
      expect { artifacts.write('../../etc/passwd', described_class::STATUS_FAILED) }
        .to raise_error(Gitlab::PrinciplesDistiller::Workspace::PathTraversalError)
    end
  end
end
