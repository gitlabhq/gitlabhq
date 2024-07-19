# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::WorkItems::Widgets::CrmContactsUpdateInputType, feature_category: :service_desk do
  it { expect(described_class.graphql_name).to eq('WorkItemWidgetCrmContactsUpdateInput') }

  it { expect(described_class.arguments.keys).to match_array(%w[contactIds operationMode]) }
end
