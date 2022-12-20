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
end
