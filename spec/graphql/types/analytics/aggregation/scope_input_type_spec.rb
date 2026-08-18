# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Analytics::Aggregation::ScopeInputType, feature_category: :value_stream_management do
  it 'has the expected graphql name' do
    expect(described_class.graphql_name).to eq('AggregationScopeInput')
  end

  describe '#prepare' do
    let(:max_sources) { described_class::MAX_SOURCES }

    def prepare(input)
      described_class.coerce_isolated_input(input).prepare
    end

    it 'accepts up to MAX_SOURCES combined paths' do
      input = {
        group_full_paths: Array.new(max_sources - 1) { |i| "group-#{i}" },
        project_full_paths: ['group/project']
      }

      expect(prepare(input).to_h).to eq(input)
    end

    it 'accepts omitted arguments' do
      expect(prepare({}).to_h).to eq({})
    end

    it 'does not count case-insensitive duplicates towards the limit' do
      input = {
        group_full_paths: Array.new(max_sources) { |i| "group-#{i}" },
        project_full_paths: ['GROUP-0']
      }

      expect { prepare(input) }.not_to raise_error
    end

    it 'rejects more than MAX_SOURCES combined paths' do
      input = {
        group_full_paths: Array.new(max_sources) { |i| "group-#{i}" },
        project_full_paths: ['group/project']
      }

      expect { prepare(input) }.to raise_error(
        Gitlab::Graphql::Errors::ArgumentError,
        "groupFullPaths and projectFullPaths arguments combined must not exceed #{max_sources}"
      )
    end
  end
end
