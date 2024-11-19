# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > User sees sidebar', :js, feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:project) { create(:project, :private, public_builds: false, namespace: user.namespace) }

  # NOTE: See documented behaviour https://design.gitlab.com/regions/navigation#contextual-navigation
  context 'on different viewports', :js do
    include MobileHelpers

    before do
      sign_in(user)
    end

    shared_examples 'has an expanded nav sidebar' do
      it 'has an expanded nav sidebar on load that can be collapsed' do
        expect(page).to have_selector('[data-testid="super-sidebar-collapse-button"]', visible: :visible)

        find_by_testid('super-sidebar-collapse-button').click
        expect(page).to have_selector('[data-testid="super-sidebar-collapse-button"]', visible: :hidden)
      end
    end

    shared_examples 'has a collapsed nav sidebar' do
      it 'has a collapsed nav sidebar on load that can be expanded' do
        expect(page).to have_selector('[data-testid="super-sidebar-collapse-button"]', visible: :hidden)

        page.find('.js-super-sidebar-toggle-expand').click
        expect(page).to have_selector('[data-testid="super-sidebar-collapse-button"]', visible: :visible)
      end
    end

    context 'with a extra small viewport' do
      before do
        resize_screen_xs
        visit project_path(project)
      end

      it_behaves_like 'has a collapsed nav sidebar'
    end

    context 'with a small size viewport' do
      before do
        resize_screen_sm
        visit project_path(project)
      end

      it_behaves_like 'has a collapsed nav sidebar'
    end

    context 'with medium size viewport' do
      before do
        resize_window(768, 800)
        visit project_path(project)
      end

      it_behaves_like 'has a collapsed nav sidebar'
    end

    context 'with viewport size 1199px' do
      before do
        resize_window(1199, 800)
        visit project_path(project)
      end

      it_behaves_like 'has a collapsed nav sidebar'
    end

    context 'with a extra large viewport' do
      before do
        resize_window(1200, 800)
        visit project_path(project)
      end

      it_behaves_like 'has an expanded nav sidebar'
    end
  end

  context 'as owner' do
    before do
      sign_in(user)
    end

    context 'when snippets are disabled' do
      before do
        project.project_feature.update_attribute('snippets_access_level', ProjectFeature::DISABLED)
      end

      it 'does not display a "Snippets" link' do
        visit project_path(project)

        within_testid('super-sidebar') do
          expect(page).not_to have_button 'Code'
        end
      end
    end
  end

  context 'as anonymous' do
    let(:project) { create(:project, :public) }
    let!(:issue) { create(:issue, :opened, project: project, author: user) }

    describe 'project landing page' do
      before do
        project.project_feature.update!(
          builds_access_level: ProjectFeature::DISABLED,
          merge_requests_access_level: ProjectFeature::DISABLED,
          repository_access_level: ProjectFeature::DISABLED,
          issues_access_level: ProjectFeature::DISABLED,
          wiki_access_level: ProjectFeature::DISABLED
        )
      end

      it 'does not show the project file list landing page, but the activity' do
        visit project_path(project)

        expect(page).not_to have_selector '.project-stats'
        expect(page).not_to have_selector '.project-last-commit'
        expect(page).not_to have_selector '.project-show-files'
        expect(page).to have_selector '.project-show-activity'
      end

      it 'shows the wiki when enabled' do
        project.project_feature.update!(wiki_access_level: ProjectFeature::ENABLED)

        visit project_path(project)

        expect(page).to have_selector '.project-show-wiki'
      end

      it 'shows the issues when enabled' do
        project.project_feature.update!(issues_access_level: ProjectFeature::ENABLED)

        visit project_path(project)

        expect(page).to have_selector '.issues-list'
      end

      it 'shows the wiki when wiki and issues are enabled' do
        project.project_feature.update!(
          issues_access_level: ProjectFeature::ENABLED,
          wiki_access_level: ProjectFeature::ENABLED
        )

        visit project_path(project)

        expect(page).to have_selector '.project-show-wiki'
      end
    end
  end

  context 'as guest' do
    let(:guest) { create(:user) }
    let!(:issue) { create(:issue, :opened, project: project, author: guest) }

    before do
      project.add_guest(guest)

      sign_in(guest)
    end

    it 'shows allowed tabs only' do
      visit project_path(project)

      within_testid('super-sidebar') do
        expect(page).to have_button 'Pinned'
        expect(page).to have_button 'Manage'
        expect(page).to have_button 'Plan'
        expect(page).to have_button 'Code'
        expect(page).to have_button 'Monitor'
        expect(page).to have_button 'Analyze'

        expect(page).not_to have_button 'Build'

        click_button 'Code'
        expect(page).not_to have_link 'Repository'
        expect(page).not_to have_link 'Merge requests'
      end
    end

    it 'shows build tab if builds are public' do
      project.public_builds = true
      project.save!

      visit project_path(project)

      within_testid('super-sidebar') do
        expect(page).to have_button 'Build'
      end
    end

    it 'does not show fork button' do
      visit project_path(project)

      within('.project-repo-buttons') do
        expect(page).not_to have_link 'Fork'
      end
    end

    it 'does not show clone path' do
      visit project_path(project)

      within('.project-repo-buttons') do
        expect(page).not_to have_selector '.project-code-holder'
      end
    end

    describe 'project landing page' do
      before do
        project.project_feature.update!(
          issues_access_level: ProjectFeature::DISABLED,
          wiki_access_level: ProjectFeature::DISABLED
        )
      end

      it 'does not show the project file list landing page' do
        visit project_path(project)

        expect(page).not_to have_selector '.project-stats'
        expect(page).not_to have_selector '.project-last-commit'
        expect(page).not_to have_selector '.project-show-files'
        expect(page).to have_selector '.project-show-activity'
      end

      it 'shows the project activity when issues and wiki are disabled' do
        visit project_path(project)

        expect(page).to have_selector '.project-show-activity'
      end

      it 'shows the wiki when enabled' do
        project.project_feature.update!(wiki_access_level: ProjectFeature::PRIVATE)

        visit project_path(project)

        expect(page).to have_selector '.project-show-wiki'
      end

      it 'shows the issues when enabled' do
        project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)

        visit project_path(project)

        expect(page).to have_selector '.issues-list'
      end
    end
  end
end
