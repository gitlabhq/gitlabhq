# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User changes public project visibility', :js, feature_category: :groups_and_projects do
  include ProjectForksHelper

  let_it_be_with_reload(:project) { create(:project, :empty_repo, :public) }

  shared_examples 'changing visibility to private' do
    it 'requires confirmation' do
      visibility_select = find_by_testid('project-visibility-dropdown')
      visibility_select.select('Private')

      page.within('#js-shared-permissions') do
        click_button 'Save changes'
      end

      fill_in 'confirm_name_input', with: project.path_with_namespace

      page.within '.modal' do
        click_button 'Reduce project visibility'
      end

      # Wait for the success flash so project.reload does not race the full-page redirect.
      expect(page).to have_content('successfully updated')

      expect(project.reload).to be_private
    end
  end

  shared_examples 'does not require confirmation' do
    it 'saves without confirmation' do
      visibility_select = find_by_testid('project-visibility-dropdown')
      visibility_select.select('Private')

      page.within('#js-shared-permissions') do
        click_button 'Save changes'
      end

      # Wait for the success flash so project.reload does not race the full-page redirect.
      expect(page).to have_content('successfully updated')

      expect(project.reload).to be_private
    end
  end

  context 'when the project has forks' do
    let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }

    before do
      project.update!(visibility_level: visibility_level)

      fork_project(project, project.first_owner)

      sign_in(project.first_owner)

      visit edit_project_path(project)
    end

    context 'when a project is public' do
      it_behaves_like 'changing visibility to private'
    end

    context 'when the project is internal' do
      let(:visibility_level) { Gitlab::VisibilityLevel::INTERNAL }

      it_behaves_like 'changing visibility to private'
    end

    context 'when the visibility level is untouched' do
      it 'saves without confirmation' do
        expect(page).to have_selector('.js-emails-enabled', visible: :visible)
        find('.js-emails-enabled input[type="checkbox"]').click

        page.within('#js-shared-permissions') do
          click_button 'Save changes'
        end

        # Wait for the success flash so project.reload does not race the full-page redirect.
        expect(page).to have_content('successfully updated')

        expect(project.reload).to be_public
      end
    end
  end

  context 'when the project is not forked' do
    before do
      sign_in(project.first_owner)

      visit edit_project_path(project)
    end

    it_behaves_like 'does not require confirmation'
  end
end
