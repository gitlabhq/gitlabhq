require 'spec_helper'

feature 'Project settings > Merge Requests', feature: true, js: true do
  include GitlabRoutingHelper

  let(:project) { create(:empty_project, :public) }
  let(:user) { create(:user) }

  background do
    project.team << [user, :master]
    login_as(user)
  end

  context 'when Merge Request and Pipelines are initially enabled' do
    context 'when Pipelines are initially enabled' do
      before do
        visit edit_project_path(project)
      end

      scenario 'shows the Merge Requests settings' do
        expect(page).to have_content('Only allow merge requests to be merged if the pipeline succeeds')
        expect(page).to have_content('Only allow merge requests to be merged if all discussions are resolved')

        select 'Disabled', from: "project_project_feature_attributes_merge_requests_access_level"

        expect(page).not_to have_content('Only allow merge requests to be merged if the pipeline succeeds')
        expect(page).not_to have_content('Only allow merge requests to be merged if all discussions are resolved')
      end
    end

    context 'when Pipelines are initially disabled' do
      before do
        project.project_feature.update_attribute('builds_access_level', ProjectFeature::DISABLED)
        visit edit_project_path(project)
      end

      scenario 'shows the Merge Requests settings that do not depend on Builds feature' do
        expect(page).not_to have_content('Only allow merge requests to be merged if the pipeline succeeds')
        expect(page).to have_content('Only allow merge requests to be merged if all discussions are resolved')

        select 'Everyone with access', from: "project_project_feature_attributes_builds_access_level"

        expect(page).to have_content('Only allow merge requests to be merged if the pipeline succeeds')
        expect(page).to have_content('Only allow merge requests to be merged if all discussions are resolved')
      end
    end
  end

  context 'when Merge Request are initially disabled' do
    before do
      project.project_feature.update_attribute('merge_requests_access_level', ProjectFeature::DISABLED)
      visit edit_project_path(project)
    end

    scenario 'does not show the Merge Requests settings' do
      expect(page).not_to have_content('Only allow merge requests to be merged if the pipeline succeeds')
      expect(page).not_to have_content('Only allow merge requests to be merged if all discussions are resolved')

      select 'Everyone with access', from: "project_project_feature_attributes_merge_requests_access_level"

      expect(page).to have_content('Only allow merge requests to be merged if the pipeline succeeds')
      expect(page).to have_content('Only allow merge requests to be merged if all discussions are resolved')
    end
  end
end
