# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Integration settings', feature_category: :integrations do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'with Zentao integration records' do
    before do
      create(:integration, project: project, type_new: 'Integrations::Zentao', category: 'issue_tracker')
    end

    it 'shows settings without Zentao', :js do
      visit namespace_project_settings_integrations_path(namespace_id: project.namespace.full_path,
        project_id: project.path)

      expect(page).to have_content('Add an integration')
      expect(page).not_to have_content('ZenTao')
    end
  end
end
