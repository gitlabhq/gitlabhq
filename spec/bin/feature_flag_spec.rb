# frozen_string_literal: true

require 'spec_helper'

load File.expand_path('../../bin/feature-flag', __dir__)

RSpec.describe 'bin/feature-flag', feature_category: :feature_flags do
  using RSpec::Parameterized::TableSyntax

  let(:groups) do
    {
      geo: { label: 'group::geo' }
    }
  end

  before do
    allow(HTTParty)
      .to receive(:get)
        .with(FeatureFlagOptionParser::WWW_GITLAB_COM_GROUPS_JSON, format: :plain)
        .and_return(groups.to_json)
  end

  describe FeatureFlagCreator do
    let(:argv) { %w[feature-flag-name -t gitlab_com_derisk -g group::geo -a https://url -i https://url -m http://url -u username -M 16.6 -ee] }
    let(:options) { FeatureFlagOptionParser.parse(argv) }
    let(:creator) { described_class.new(options) }
    let(:existing_flags) do
      {
        'existing_feature_flag' =>
          File.join('ee', 'config', 'feature_flags', 'gitlab_com_derisk', 'existing_feature_flag.yml')
      }
    end

    before do
      allow(creator).to receive(:all_feature_flag_names) { existing_flags }
      allow(creator).to receive(:branch_name).and_return('feature-branch')
      allow(creator).to receive(:editor).and_return(nil)

      # ignore writes
      allow(File).to receive(:write).and_return(true)

      # ignore stdin
      allow(Readline).to receive(:readline).and_raise('EOF')
      allow(Gitlab::Popen).to receive(:popen).and_return(["", 0])
    end

    subject { creator.execute }

    it 'properly creates a feature flag' do
      expect(File).to receive(:write).with(
        File.join('ee', 'config', 'feature_flags', 'gitlab_com_derisk', 'feature_flag_name.yml'),
        anything)

      expect do
        subject
      end.to output(/name: feature_flag_name/).to_stdout
    end

    context 'when running on master' do
      it 'requires feature branch' do
        expect(creator).to receive(:branch_name).and_return('master')

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

    context 'when copy command not found' do
      before do
        allow(Gitlab::Popen).to receive(:popen).and_return(["", 1])
      end

      it 'shows an error' do
        expect { subject }.to raise_error(FeatureFlagHelpers::Abort, /Could not find a copy to clipboard command./)
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
        :group             | %w[foo -g group::geo]                   | 'group::geo'
        :group             | %w[foo --group group::geo]              | 'group::geo'
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
      before do
        stub_const('FeatureFlagOptionParser::TYPES',
          development: { description: 'short' },
          deprecated: { description: 'deprecated', deprecated: true },
          licensed: { description: 'licensed' }
        )
      end

      context 'when valid type is given' do
        let(:type) { 'development' }

        it 'reads type from stdin' do
          expect(Readline).to receive(:readline).and_return(type)
          expect do
            expect(described_class.read_type).to eq(:development)
          end.to output(/Specify the feature flag type/).to_stdout
        end
      end

      context 'when valid index is given' do
        it 'picks the type successfully' do
          expect(Readline).to receive(:readline).and_return('3')
          expect do
            expect(described_class.read_type).to eq(:licensed)
          end.to output(/Specify the feature flag type./).to_stdout
        end
      end

      context 'when deprecated type is given' do
        let(:type) { 'deprecated' }

        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return(type)
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_type }.to raise_error(/EOF/)
          end.to output(/Specify the feature flag type/).to_stdout
            .and output(/Invalid type specified/).to_stderr
        end
      end

      context 'when invalid type is given' do
        let(:type) { 'invalid' }

        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return(type)
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_type }.to raise_error(/EOF/)
          end.to output(/Specify the feature flag type/).to_stdout
            .and output(/Invalid type specified/).to_stderr
        end
      end

      context 'when invalid index is given' do
        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return('12')
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_type }.to raise_error(/EOF/)
          end.to output(/Specify the feature flag type/).to_stdout
            .and output(/Invalid type specified/).to_stderr
        end
      end
    end

    describe '.read_group' do
      context 'when valid group is given' do
        let(:group) { 'group::geo' }

        it 'reads group from stdin' do
          expect(Readline).to receive(:readline).and_return(group)
          expect do
            expect(described_class.read_group).to eq('group::geo')
          end.to output(/Specify the group label to which the feature flag belongs, from the following list/).to_stdout
        end
      end

      context 'when valid index is given' do
        it 'picks the group successfully' do
          expect(Readline).to receive(:readline).and_return('1')
          expect do
            expect(described_class.read_group).to eq('group::geo')
          end.to output(/Specify the group label to which the feature flag belongs, from the following list/).to_stdout
        end
      end

      context 'with invalid group given' do
        let(:type) { 'invalid' }

        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return(type)
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_group }.to raise_error(/EOF/)
          end.to output(/Specify the group label to which the feature flag belongs, from the following list/).to_stdout
            .and output(/The group label isn't in the above labels list/).to_stderr
        end
      end

      context 'when invalid index is given' do
        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return('12')
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_group }.to raise_error(/EOF/)
          end.to output(/Specify the group label to which the feature flag belongs, from the following list/).to_stdout
            .and output(/The group label isn't in the above labels list/).to_stderr
        end
      end
    end

    shared_examples 'read_url' do |method, prompt|
      context 'with valid URL given' do
        let(:url) { 'https://merge-request' }

        it 'reads URL from stdin' do
          expect(Readline).to receive(:readline).and_return(url)
          expect(HTTParty).to receive(:head).with(url).and_return(instance_double(HTTParty::Response, success?: true))

          expect do
            expect(described_class.public_send(method)).to eq('https://merge-request')
          end.to output(/#{prompt}/).to_stdout
        end
      end

      context 'with invalid URL given' do
        let(:url) { 'https://invalid' }

        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return(url)
          expect(HTTParty).to receive(:head).with(url).and_return(instance_double(HTTParty::Response, success?: false))
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.public_send(method) }.to raise_error(/EOF/)
          end.to output(/#{prompt}/).to_stdout
            .and output(/URL '#{url}' isn't valid/).to_stderr
        end
      end

      context 'with empty URL given' do
        let(:url) { '' }

        it 'skips entry' do
          expect(Readline).to receive(:readline).and_return(url)

          expect do
            expect(described_class.public_send(method)).to be_nil
          end.to output(/#{prompt}/).to_stdout
        end
      end

      context 'with a non-URL given' do
        let(:url) { 'malformed' }

        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return(url)
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.public_send(method) }.to raise_error(/EOF/)
          end.to output(/#{prompt}/).to_stdout
            .and output(/URL needs to start with/).to_stderr
        end
      end
    end

    describe '.read_feature_issue_url' do
      it_behaves_like 'read_url', :read_feature_issue_url, 'URL of the original feature issue'
    end

    describe '.read_introduced_by_url' do
      it_behaves_like 'read_url', :read_introduced_by_url, 'URL of the MR introducing the feature flag'
    end

    describe '.read_rollout_issue_url' do
      let(:options) do
        FeatureFlagOptionParser::Options.new({
          name: 'foo',
          username: 'joe',
          type: :gitlab_com_derisk,
          introduced_by_url: 'https://introduced_by_url',
          feature_issue_url: 'https://feature_issue_url',
          milestone: '16.6',
          group: 'group::geo'
        })
      end

      context 'with valid URL given' do
        let(:url) { 'https://rollout_issue_url' }

        it 'reads type from stdin' do
          expect(described_class).to receive(:copy_to_clipboard!).and_return(true)
          expect(Readline).to receive(:readline).and_return('') # enter to open the new issue url
          expect(described_class).to receive(:open_url!).and_return(true)
          expect(Readline).to receive(:readline).and_return(url)
          expect(HTTParty).to receive(:head).with(url).and_return(instance_double(HTTParty::Response, success?: true))

          expect do
            expect(described_class.read_rollout_issue_url(options)).to eq(url)
          end.to output(/URL of the rollout issue/).to_stdout
        end
      end

      context 'with invalid URL given' do
        let(:url) { 'https://invalid' }

        it 'shows error message and retries' do
          expect(described_class).to receive(:copy_to_clipboard!).and_return(true)
          expect(Readline).to receive(:readline).and_return('') # enter to open the new issue url
          expect(described_class).to receive(:open_url!).and_return(true)
          expect(Readline).to receive(:readline).and_return(url)
          expect(HTTParty).to receive(:head).with(url).and_return(instance_double(HTTParty::Response, success?: false))
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_rollout_issue_url(options) }.to raise_error(/EOF/)
          end.to output(/URL of the rollout issue/).to_stdout
            .and output(/URL '#{url}' isn't valid/).to_stderr
        end
      end

      context 'with a non-URL given' do
        let(:url) { 'malformed' }

        it 'shows error message and retries' do
          expect(described_class).to receive(:copy_to_clipboard!).and_return(true)
          expect(Readline).to receive(:readline).and_return('') # enter to open the new issue url
          expect(described_class).to receive(:open_url!).and_return(true)
          expect(Readline).to receive(:readline).and_return(url)
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_rollout_issue_url(options) }.to raise_error(/EOF/)
          end.to output(/URL of the rollout issue/).to_stdout
            .and output(/URL needs to start/).to_stderr
        end
      end
    end

    describe '.read_ee' do
      context 'with valid ee setting is given' do
        let(:ee) { '1' }

        it 'reads ee from stdin' do
          expect(Readline).to receive(:readline).and_return(ee)
          expect do
            expect(described_class.read_ee).to eq(true)
          end.to output(/Is this an EE only feature/).to_stdout
        end
      end
    end
  end
end
