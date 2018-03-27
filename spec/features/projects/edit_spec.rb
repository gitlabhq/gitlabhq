require 'rails_helper'

feature 'Project edit', :js do
  let(:admin)   { create(:admin) }
  let(:user)    { create(:user) }
  let(:project) { create(:project) }

  context 'feature visibility' do
    before do
      project.add_master(user)
      sign_in(user)

      visit edit_project_path(project)
    end

    context 'merge requests select' do
      it 'hides merge requests section' do
        find('.project-feature-controls[data-for="project[project_feature_attributes][merge_requests_access_level]"] .project-feature-toggle').click

        expect(page).to have_selector('.merge-requests-feature', visible: false)
      end

      context 'given project with merge_requests_disabled access level' do
        let(:project) { create(:project, :merge_requests_disabled) }

        it 'hides merge requests section' do
          expect(page).to have_selector('.merge-requests-feature', visible: false)
        end
      end
    end

    context 'builds select' do
      it 'hides builds select section' do
        find('.project-feature-controls[data-for="project[project_feature_attributes][builds_access_level]"] .project-feature-toggle').click

        expect(page).to have_selector('.builds-feature', visible: false)
      end

      context 'given project with builds_disabled access level' do
        let(:project) { create(:project, :builds_disabled) }

        it 'hides builds select section' do
          expect(page).to have_selector('.builds-feature', visible: false)
        end
      end
    end
  end

  context 'LFS enabled setting' do
    before do
      sign_in(admin)
    end

    it 'displays the correct elements' do
      allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
      visit edit_project_path(project)

      expect(page).to have_content('Git Large File Storage')
      expect(page).to have_selector('input[name="project[lfs_enabled]"] + button', visible: true)
    end
  end
end
