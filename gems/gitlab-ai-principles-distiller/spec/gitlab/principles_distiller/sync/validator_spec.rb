# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../support/tmpdir'
require_relative '../../../../lib/gitlab/principles_distiller/sync'

RSpec.describe Gitlab::PrinciplesDistiller::Sync::Validator do
  include TmpdirHelper

  let(:tmpdir) { mktmpdir }
  let(:validator) { described_class.new }
  let(:manifest_dir) { File.join(tmpdir, '.ai', 'principles') }
  let(:doc_dir) { File.join(tmpdir, 'doc') }

  let(:manifest_yaml) do
    <<~YAML
      principles:
        backend:
          owner_team: '@gitlab-org/maintainers/rails-backend'
          sources:
            - path: doc/present.md
            - path: doc/renamed.md
    YAML
  end

  before do
    Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
    FileUtils.mkdir_p(manifest_dir)
    FileUtils.mkdir_p(doc_dir)
    File.write(File.join(manifest_dir, 'manifest.yml'), manifest_yaml)
    stub_const('ARGV', [])
  end

  describe '#run' do
    context 'when every referenced SSOT source file exists' do
      before do
        File.write(File.join(doc_dir, 'present.md'), 'content')
        File.write(File.join(doc_dir, 'renamed.md'), 'content')
      end

      it 'does not abort' do
        expect { validator.run }.not_to raise_error
      end

      it 'reports success' do
        expect { validator.run }.to output(/reference existing SSOT source files/).to_stdout
      end
    end

    context 'when a referenced SSOT source file is missing' do
      before do
        File.write(File.join(doc_dir, 'present.md'), 'content')
      end

      it 'aborts, listing the missing path but not the existing one' do
        expect { validator.run }
          .to raise_error(SystemExit)
          .and output(%r{doc/renamed\.md}).to_stderr
          .and output(%r{\A(?!.*doc/present\.md).*\z}m).to_stderr
      end
    end

    context 'when a referenced doc was converted to a directory with an _index.md' do
      before do
        File.write(File.join(doc_dir, 'present.md'), 'content')
        FileUtils.mkdir_p(File.join(doc_dir, 'renamed'))
        File.write(File.join(doc_dir, 'renamed', '_index.md'), 'content')
      end

      it 'resolves via the _index.md fallback and does not abort' do
        expect { validator.run }.not_to raise_error
      end
    end

    context 'when a static_entries path is missing' do
      let(:manifest_yaml) do
        <<~YAML
          static_entries:
            - description: Code style
              path: .ai/missing-static.md
          principles:
            backend:
              owner_team: '@gitlab-org/maintainers/rails-backend'
              sources:
                - path: doc/present.md
        YAML
      end

      before do
        File.write(File.join(doc_dir, 'present.md'), 'content')
      end

      it 'aborts, naming the missing static entry' do
        expect { validator.run }
          .to raise_error(SystemExit)
          .and output(%r{\.ai/missing-static\.md}).to_stderr
      end
    end

    context 'when a principle is misconfigured (missing owner_team)' do
      let(:manifest_yaml) do
        <<~YAML
          principles:
            backend:
              sources:
                - path: doc/missing.md
        YAML
      end

      it 'aborts during manifest.load validation before the source-existence check' do
        expect { validator.run }
          .to raise_error(SystemExit)
          .and output(/owner_team/).to_stderr
      end
    end
  end
end
