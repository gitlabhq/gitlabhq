# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::Tracking::EventInputType, feature_category: :application_instrumentation do
  it { expect(described_class.graphql_name).to eq('TrackingEventInput') }

  it { expect(described_class.arguments.keys).to match_array(%w[action category extra label property value]) }
end
