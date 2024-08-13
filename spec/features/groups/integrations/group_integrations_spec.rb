# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group integrations', :js, feature_category: :integrations do
  include_context 'group integration activation'

  before do
    stub_feature_flags(remove_monitor_metrics: false)
  end

  it_behaves_like 'integration settings form' do
    let(:integrations) { Integration.find_or_initialize_all_non_project_specific(Integration.for_group(group)) }

    def navigate_to_integration(integration)
      visit_group_integration(integration.title)
    end
  end

  context 'with remove_monitor_metrics flag enabled' do
    before do
      stub_feature_flags(remove_monitor_metrics: true)
    end

    it 'returns a 404 for the prometheus edit page' do
      visit edit_group_settings_integration_path(group, :prometheus)

      expect(page).to have_content "Page not found"
    end
  end
end
