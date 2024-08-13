# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project integrations', :js, feature_category: :integrations do
  include_context 'project integration activation'

  it_behaves_like 'integration settings form' do
    let(:integrations) { project.find_or_initialize_integrations }

    def navigate_to_integration(integration)
      visit_project_integration(integration.title)
    end
  end

  context 'with remove_monitor_metrics flag enabled' do
    before do
      stub_feature_flags(remove_monitor_metrics: true)
    end

    it 'returns a 404 for the prometheus edit page' do
      visit edit_project_settings_integration_path(project, :prometheus)

      expect(page).to have_content "Page not found"
    end
  end
end
