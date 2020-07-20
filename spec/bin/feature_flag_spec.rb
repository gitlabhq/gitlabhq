# frozen_string_literal: true

require 'spec_helper'

load File.expand_path('../../bin/feature-flag', __dir__)

RSpec.describe 'bin/feature-flag' do
  using RSpec::Parameterized::TableSyntax

  describe FeatureFlagCreator do
    let(:argv) { %w[feature-flag-name -t development -g group::memory -i https://url] }
    let(:options) { FeatureFlagOptionParser.parse(argv) }
    let(:creator) { described_class.new(options) }
    let(:existing_flag) { File.join('config', 'feature_flags', 'development', 'existing-feature-flag.yml') }

    before do
      # create a dummy feature flag
      FileUtils.mkdir_p(File.dirname(existing_flag))
      File.write(existing_flag, '{}')

      # ignore writes
      allow(File).to receive(:write).and_return(true)

      # ignore stdin
      allow($stdin).to receive(:gets).and_raise('EOF')

      # ignore Git commands
      allow(creator).to receive(:branch_name) { 'feature-branch' }
    end

    after do
      FileUtils.rm_f(existing_flag)
    end

    subject { creator.execute }

    it 'properly creates a feature flag' do
      expect(File).to receive(:write).with(
        File.join('config', 'feature_flags', 'development', 'feature-flag-name.yml'),
        anything)

      expect do
        subject
      end.to output(/name: feature-flag-name/).to_stdout
    end

    context 'when running on master' do
      it 'requires feature branch' do
        expect(creator).to receive(:branch_name) { 'master' }

        expect { subject }.to raise_error(FeatureFlagHelpers::Abort, /Create a branch first/)
      end
    end

    context 'validates feature flag name' do
      where(:argv, :ex) do
        %w[.invalid.feature.flag] | /Provide a name for the feature flag that is/
        %w[existing-feature-flag] | /already exists!/
      end

      with_them do
        it do
          expect { subject }.to raise_error(ex)
        end
      end
    end
  end

  describe FeatureFlagOptionParser do
    describe '.parse' do
      where(:param, :argv, :result) do
        :name              | %w[foo]                                 | 'foo'
        :amend             | %w[foo --amend]                         | true
        :force             | %w[foo -f]                              | true
        :force             | %w[foo --force]                         | true
        :ee                | %w[foo -e]                              | true
        :ee                | %w[foo --ee]                            | true
        :introduced_by_url | %w[foo -m https://url]                  | 'https://url'
        :introduced_by_url | %w[foo --introduced-by-url https://url] | 'https://url'
        :rollout_issue_url | %w[foo -i https://url]                  | 'https://url'
        :rollout_issue_url | %w[foo --rollout-issue-url https://url] | 'https://url'
        :dry_run           | %w[foo -n]                              | true
        :dry_run           | %w[foo --dry-run]                       | true
        :type              | %w[foo -t development]                  | :development
        :type              | %w[foo --type development]              | :development
        :type              | %w[foo -t invalid]                      | nil
        :type              | %w[foo --type invalid]                  | nil
        :group             | %w[foo -g group::memory]                | 'group::memory'
        :group             | %w[foo --group group::memory]           | 'group::memory'
        :group             | %w[foo -g invalid]                      | nil
        :group             | %w[foo --group invalid]                 | nil
      end

      with_them do
        it do
          options = described_class.parse(Array(argv))

          expect(options.public_send(param)).to eq(result)
        end
      end

      it 'missing feature flag name' do
        expect do
          expect { described_class.parse(%w[--amend]) }.to output(/Feature flag name is required/).to_stdout
        end.to raise_error(FeatureFlagHelpers::Abort)
      end

      it 'parses -h' do
        expect do
          expect { described_class.parse(%w[foo -h]) }.to output(/Usage:/).to_stdout
        end.to raise_error(FeatureFlagHelpers::Done)
      end
    end

    describe '.read_type' do
      let(:type) { 'development' }

      it 'reads type from $stdin' do
        expect($stdin).to receive(:gets).and_return(type)
        expect do
          expect(described_class.read_type).to eq(:development)
        end.to output(/specify the type/).to_stdout
      end

      context 'invalid type given' do
        let(:type) { 'invalid' }

        it 'shows error message and retries' do
          expect($stdin).to receive(:gets).and_return(type)
          expect($stdin).to receive(:gets).and_raise('EOF')

          expect do
            expect { described_class.read_type }.to raise_error(/EOF/)
          end.to output(/specify the type/).to_stdout
            .and output(/Invalid type specified/).to_stderr
        end
      end
    end

    describe '.read_group' do
      let(:group) { 'group::memory' }

      it 'reads type from $stdin' do
        expect($stdin).to receive(:gets).and_return(group)
        expect do
          expect(described_class.read_group).to eq('group::memory')
        end.to output(/specify the group/).to_stdout
      end

      context 'invalid group given' do
        let(:type) { 'invalid' }

        it 'shows error message and retries' do
          expect($stdin).to receive(:gets).and_return(type)
          expect($stdin).to receive(:gets).and_raise('EOF')

          expect do
            expect { described_class.read_group }.to raise_error(/EOF/)
          end.to output(/specify the group/).to_stdout
            .and output(/Group needs to include/).to_stderr
        end
      end
    end

    describe '.rollout_issue_url' do
      let(:options) { OpenStruct.new(name: 'foo', type: :development) }
      let(:url) { 'https://issue' }

      it 'reads type from $stdin' do
        expect($stdin).to receive(:gets).and_return(url)
        expect do
          expect(described_class.read_issue_url(options)).to eq('https://issue')
        end.to output(/Paste URL here/).to_stdout
      end

      context 'invalid URL given' do
        let(:type) { 'invalid' }

        it 'shows error message and retries' do
          expect($stdin).to receive(:gets).and_return(type)
          expect($stdin).to receive(:gets).and_raise('EOF')

          expect do
            expect { described_class.read_issue_url(options) }.to raise_error(/EOF/)
          end.to output(/Paste URL here/).to_stdout
            .and output(/URL needs to start/).to_stderr
        end
      end
    end
  end
end
