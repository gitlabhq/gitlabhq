require 'spec_helper'

feature 'Project settings > Merge Requests', :js do
  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }

  background do
    project.add_master(user)
    sign_in(user)
  end

  context 'when Merge Request and Pipelines are initially enabled' do
    context 'when Pipelines are initially enabled' do
      before do
        visit edit_project_path(project)
      end

      scenario 'shows the Merge Requests settings' do
        expect(page).to have_content('Only allow merge requests to be merged if the pipeline succeeds')
        expect(page).to have_content('Only allow merge requests to be merged if all discussions are resolved')

        within('.sharing-permissions-form') do
          find('.project-feature-controls[data-for="project[project_feature_attributes][merge_requests_access_level]"] .project-feature-toggle').click
          find('input[value="Save changes"]').send_keys(:return)
        end

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

        within('.sharing-permissions-form') do
          find('.project-feature-controls[data-for="project[project_feature_attributes][builds_access_level]"] .project-feature-toggle').click
          find('input[value="Save changes"]').send_keys(:return)
        end

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

      within('.sharing-permissions-form') do
        find('.project-feature-controls[data-for="project[project_feature_attributes][merge_requests_access_level]"] .project-feature-toggle').click
        find('input[value="Save changes"]').send_keys(:return)
      end

      expect(page).to have_content('Only allow merge requests to be merged if the pipeline succeeds')
      expect(page).to have_content('Only allow merge requests to be merged if all discussions are resolved')
    end
  end

  describe 'Checkbox to enable merge request link' do
    before do
      visit edit_project_path(project)
    end

    scenario 'is initially checked' do
      checkbox = find_field('project_printing_merge_request_link_enabled')
      expect(checkbox).to be_checked
    end

    scenario 'when unchecked sets :printing_merge_request_link_enabled to false' do
      uncheck('project_printing_merge_request_link_enabled')
      within('.merge-request-settings-form') do
        click_on('Save changes')
      end

      # Wait for save to complete and page to reload
      checkbox = find_field('project_printing_merge_request_link_enabled')
      expect(checkbox).not_to be_checked

      project.reload
      expect(project.printing_merge_request_link_enabled).to be(false)
    end
  end
end
