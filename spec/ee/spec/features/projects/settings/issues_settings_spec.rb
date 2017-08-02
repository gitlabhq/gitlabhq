require 'spec_helper'

describe 'Project settings > [EE] Merge Requests', :js do
  include GitlabRoutingHelper

  let(:user) { create(:user) }
  let(:project) { create(:empty_project, approvals_before_merge: 1) }

  before do
    gitlab_sign_in(user)
    project.team << [user, :master]
  end

  context 'issuable default templates feature not available' do
    before do
      stub_licensed_features(issuable_default_templates: false)
    end

    scenario 'input to configure issue template is not shown' do
      visit edit_project_path(project)

      expect(page).not_to have_selector('#project_issues_template')
    end
  end

  context 'issuable default templates feature is available' do
    before do
      stub_licensed_features(issuable_default_templates: true)
    end

    scenario 'input to configure issue template is not shown' do
      visit edit_project_path(project)

      expect(page).to have_selector('#project_issues_template')
    end
  end
end
