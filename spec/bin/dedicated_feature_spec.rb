# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

require_relative '../../bin/dedicated-feature'

RSpec.describe 'bin/dedicated-feature', feature_category: :feature_flags do
  using RSpec::Parameterized::TableSyntax

  let(:groups) { { geo: { label: 'group::geo' } } }

  before do
    allow(HTTParty)
      .to receive(:get)
        .with(FeatureGenerator::Shared::WWW_GITLAB_COM_GROUPS_JSON, format: :plain)
        .and_return(groups.to_json)
  end

  describe DedicatedFeatureCreator do
    let(:argv) { %w[dedicated-feature-name -g group::geo -m https://url -M 16.6] }
    let(:options) { DedicatedFeatureOptionParser.parse(argv) }
    let(:creator) { described_class.new(options) }
    let(:existing_dedicated_features) do
      { 'existing_dedicated_feature' => File.join('ee', 'config', 'dedicated_features',
        'existing_dedicated_feature.yml') }
    end

    before do
      allow(creator).to receive(:all_dedicated_feature_names) { existing_dedicated_features }
      allow(creator).to receive_messages(branch_name: 'feature-branch', editor: nil)

      allow(File).to receive(:write).and_return(true)
      allow(Readline).to receive(:readline).and_raise('EOF')
    end

    subject(:execute) { creator.execute }

    it 'properly creates a Dedicated feature', :aggregate_failures do
      expect(File).to receive(:write).with(
        File.join('ee', 'config', 'dedicated_features', 'dedicated_feature_name.yml'),
        anything)

      expect { execute }.to output(/name: dedicated_feature_name/).to_stdout
    end

    context 'when running on master' do
      it 'requires feature branch' do
        expect(creator).to receive(:branch_name).and_return('master')

        expect { execute }.to raise_error(FeatureGenerator::Shared::Abort, /Create a branch first/)
      end
    end

    context 'with Dedicated feature name validation' do
      where(:argv, :ex) do
        %w[.invalid.dedicated.feature] | /Provide a name for the Dedicated feature that is/
        %w[existing-dedicated-feature] | /already exists!/
      end

      with_them do
        specify do
          expect { execute }.to raise_error(ex)
        end
      end
    end
  end

  describe DedicatedFeatureOptionParser do
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
        :milestone         | %w[foo -M 16.6]                         | '16.6'
        :milestone         | %w[foo --milestone 16.6]                | '16.6'
        :group             | %w[foo -g group::geo]                   | 'group::geo'
        :group             | %w[foo --group group::geo]              | 'group::geo'
        :group             | %w[foo -g invalid]                      | nil
        :group             | %w[foo --group invalid]                 | nil
      end

      with_them do
        specify do
          options = described_class.parse(Array(argv))

          expect(options.public_send(param)).to eq(result)
        end
      end

      it 'missing Dedicated feature name' do
        expect do
          expect { described_class.parse(%w[--amend]) }.to output(/Dedicated feature name is required/).to_stdout
        end.to raise_error(FeatureGenerator::Shared::Abort)
      end

      it 'parses -h' do
        expect do
          expect { described_class.parse(%w[foo -h]) }.to output(/Usage:/).to_stdout
        end.to raise_error(FeatureGenerator::Shared::Done)
      end
    end

    describe '.read_group' do
      it 'uses the Dedicated feature noun in the prompt' do
        allow(described_class).to receive(:fzf_available?).and_return(false)
        expect(Readline).to receive(:readline).and_return('group::geo')

        expect { described_class.read_group }
          .to output(/Dedicated feature/).to_stdout
      end
    end

    describe '.read_introduced_by_url' do
      it 'uses the Dedicated feature noun in the prompt' do
        expect(Readline).to receive(:readline).and_return('')

        expect { described_class.read_introduced_by_url }
          .to output(/Dedicated feature/).to_stdout
      end
    end
  end
end
