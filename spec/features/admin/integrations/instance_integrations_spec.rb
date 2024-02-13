# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Instance integrations', :js, feature_category: :integrations do
  include_context 'instance integration activation'

  before do
    stub_feature_flags(remove_monitor_metrics: false)
  end

  it_behaves_like 'integration settings form' do
    let(:integrations) do
      Integration.find_or_initialize_all_non_project_specific(
        Integration.for_instance, include_instance_specific: true
      )
    end

    def navigate_to_integration(integration)
      visit_instance_integration(integration.title)
    end
  end
end
