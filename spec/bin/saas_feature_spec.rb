# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

require_relative '../../bin/saas-feature'

RSpec.describe 'bin/saas-feature', feature_category: :feature_flags do
  using RSpec::Parameterized::TableSyntax

  let(:groups) { { geo: { label: 'group::geo' } } }

  before do
    allow(HTTParty)
      .to receive(:get)
        .with(SaasFeatureOptionParser::WWW_GITLAB_COM_GROUPS_JSON, format: :plain)
        .and_return(groups.to_json)
  end

  describe SaasFeatureCreator do
    let(:argv) { %w[saas-feature-name -g group::geo -m http://url -M 16.6] }
    let(:options) { SaasFeatureOptionParser.parse(argv) }
    let(:creator) { described_class.new(options) }
    let(:existing_saas_features) do
      { 'existing_saas_feature' => File.join('ee', 'config', 'saas_features', 'existing_saas_feature.yml') }
    end

    before do
      allow(creator).to receive(:all_saas_feature_names) { existing_saas_features }
      allow(creator).to receive(:branch_name).and_return('feature-branch')
      allow(creator).to receive(:editor).and_return(nil)

      # ignore writes
      allow(File).to receive(:write).and_return(true)

      # ignore stdin
      allow(Readline).to receive(:readline).and_raise('EOF')
    end

    subject(:execute) { creator.execute }

    it 'properly creates a SaaS feature' do
      expect(File).to receive(:write).with(
        File.join('ee', 'config', 'saas_features', 'saas_feature_name.yml'),
        anything)

      expect { execute }.to output(/name: saas_feature_name/).to_stdout
    end

    context 'when running on master' do
      it 'requires feature branch' do
        expect(creator).to receive(:branch_name).and_return('master')

        expect { execute }.to raise_error(SaasFeatureHelpers::Abort, /Create a branch first/)
      end
    end

    context 'with SaaS feature name validation' do
      where(:argv, :ex) do
        %w[.invalid.saas.feature] | /Provide a name for the SaaS feature that is/
        %w[existing-saas-feature] | /already exists!/
      end

      with_them do
        it do
          expect { execute }.to raise_error(ex)
        end
      end
    end
  end

  describe SaasFeatureOptionParser do
    describe '.parse' do
      where(:param, :argv, :result) do
        :name              | %w[foo]                                 | 'foo'
        :amend             | %w[foo --amend]                         | true
        :force             | %w[foo -f]                              | true
        :force             | %w[foo --force]                         | true
        :introduced_by_url | %w[foo -m https://url]                  | 'https://url'
        :introduced_by_url | %w[foo --introduced-by-url https://url] | 'https://url'
        :dry_run           | %w[foo -n]                              | true
        :dry_run           | %w[foo --dry-run]                       | true
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

      it 'missing SaaS feature name' do
        expect do
          expect { described_class.parse(%w[--amend]) }.to output(/SaaS feature name is required/).to_stdout
        end.to raise_error(SaasFeatureHelpers::Abort)
      end

      it 'parses -h' do
        expect do
          expect { described_class.parse(%w[foo -h]) }.to output(/Usage:/).to_stdout
        end.to raise_error(SaasFeatureHelpers::Done)
      end
    end

    describe '.read_group' do
      before do
        allow(described_class).to receive(:fzf_available?).and_return(false)
      end

      context 'when valid group is given' do
        let(:group) { 'group::geo' }

        it 'reads group from stdin' do
          expect(Readline).to receive(:readline).and_return(group)
          expect do
            expect(described_class.read_group).to eq('group::geo')
          end.to output(/Specify the group label to which the SaaS feature belongs, from the following list/).to_stdout
        end
      end

      context 'when valid index is given' do
        it 'picks the group successfully' do
          expect(Readline).to receive(:readline).and_return('1')
          expect do
            expect(described_class.read_group).to eq('group::geo')
          end.to output(/Specify the group label to which the SaaS feature belongs, from the following list/).to_stdout
        end
      end

      context 'with invalid group given' do
        let(:type) { 'invalid' }

        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return(type)
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_group }.to raise_error(/EOF/)
          end.to output(/Specify the group label to which the SaaS feature belongs, from the following list/).to_stdout
            .and output(/The group label isn't in the above labels list/).to_stderr
        end
      end

      context 'when invalid index is given' do
        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return('12')
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_group }.to raise_error(/EOF/)
          end.to output(/Specify the group label to which the SaaS feature belongs, from the following list/).to_stdout
            .and output(/The group label isn't in the above labels list/).to_stderr
        end
      end
    end

    describe '.read_introduced_by_url' do
      context 'with valid URL given' do
        let(:url) { 'https://merge-request' }

        it 'reads URL from stdin' do
          expect(Readline).to receive(:readline).and_return(url)
          expect(HTTParty).to receive(:head).with(url).and_return(instance_double(HTTParty::Response, success?: true))

          expect do
            expect(described_class.read_introduced_by_url).to eq('https://merge-request')
          end.to output(/URL of the MR introducing the SaaS feature/).to_stdout
        end
      end

      context 'with invalid URL given' do
        let(:url) { 'https://invalid' }

        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return(url)
          expect(HTTParty).to receive(:head).with(url).and_return(instance_double(HTTParty::Response, success?: false))
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_introduced_by_url }.to raise_error(/EOF/)
          end.to output(/URL of the MR introducing the SaaS feature/).to_stdout
                                                                     .and output(/URL '#{url}' isn't valid/).to_stderr
        end
      end

      context 'with empty URL given' do
        let(:url) { '' }

        it 'skips entry' do
          expect(Readline).to receive(:readline).and_return(url)

          expect do
            expect(described_class.read_introduced_by_url).to be_nil
          end.to output(/URL of the MR introducing the SaaS feature/).to_stdout
        end
      end

      context 'with a non-URL given' do
        let(:url) { 'malformed' }

        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return(url)
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_introduced_by_url }.to raise_error(/EOF/)
          end.to output(/URL of the MR introducing the SaaS feature/).to_stdout
                                                                     .and output(/URL needs to start with/).to_stderr
        end
      end
    end
  end
end
