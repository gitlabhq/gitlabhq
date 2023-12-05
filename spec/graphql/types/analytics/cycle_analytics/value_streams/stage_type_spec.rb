# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Analytics::CycleAnalytics::ValueStreams::StageType, feature_category: :value_stream_management do
  let(:fields) do
    %i[
      name start_event_identifier
      end_event_identifier hidden custom
    ]
  end

  specify { expect(described_class.graphql_name).to eq('ValueStreamStage') }
  specify { expect(described_class).to have_graphql_fields(fields).at_least }
end
