require 'spec_helper'

feature 'Project settings > Issues', :js do
  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }

  background do
    project.add_master(user)

    sign_in(user)
  end

  context 'when Issues are initially enabled' do
    context 'when Pipelines are initially enabled' do
      before do
        visit edit_project_path(project)
      end

      scenario 'shows the Issues settings' do
        expect(page).to have_content('Customize your issue restrictions')

        within('.sharing-permissions-form') do
          find('.project-feature-controls[data-for="project[project_feature_attributes][issues_access_level]"] .project-feature-toggle').click
          click_on('Save changes')
        end

        expect(page).not_to have_content('Customize your issue restrictions')
      end
    end
  end

  context 'when Issues are initially disabled' do
    before do
      project.project_feature.update_attribute('issues_access_level', ProjectFeature::DISABLED)
      visit edit_project_path(project)
    end

    scenario 'does not show the Issues settings' do
      expect(page).not_to have_content('Customize your issue restrictions')

      within('.sharing-permissions-form') do
        find('.project-feature-controls[data-for="project[project_feature_attributes][issues_access_level]"] .project-feature-toggle').click
        click_on('Save changes')
      end

      expect(page).to have_content('Customize your issue restrictions')
    end
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
