# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::WorkItems::Widgets::CrmContactsCreateInputType, feature_category: :service_desk do
  it { expect(described_class.graphql_name).to eq('WorkItemWidgetCrmContactsCreateInput') }

  it { expect(described_class.arguments.keys).to match_array(%w[contactIds]) }
end
