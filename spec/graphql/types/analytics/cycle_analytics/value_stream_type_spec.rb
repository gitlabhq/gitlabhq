# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Analytics::CycleAnalytics::ValueStreamType, feature_category: :value_stream_management do
  specify { expect(described_class.graphql_name).to eq('ValueStream') }

  specify { expect(described_class).to require_graphql_authorizations(:read_cycle_analytics) }

  specify { expect(described_class).to have_graphql_fields(:id, :name, :namespace, :project, :stages) }
end
