# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Show > User interacts with dropdown actions',
  feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, :repository, group: group) }
  let_it_be(:selector) { 'groups-projects-more-actions-dropdown' }

  context 'when a user is signed in' do
    let_it_be_with_reload(:user) { create(:user) }

    context 'and the user is not a member of the project' do
      before do
        sign_in(user)
        visit project_path(project)
      end

      it 'shows correct items', :js do
        click_dropdown

        within_testid(selector) do
          expect(page).not_to have_content('Leave project')
          expect(page).to have_content("Copy project ID: #{project.id}")
          expect(page).not_to have_content('Project settings')
        end
      end
    end

    context 'and the user is added to the project' do
      before do
        project.add_member(user, role)
        sign_in(user)
        visit project_path(project)
      end

      context 'and the user has developer access' do
        let_it_be(:role) { :developer }

        it 'shows correct items', :js do
          click_dropdown

          within_testid(selector) do
            expect(page).to have_content('Leave project')
            expect(page).to have_content("Copy project ID: #{project.id}")
            expect(page).not_to have_content('Project settings')
          end
        end
      end

      context 'and the user has maintainer access' do
        let_it_be(:role) { :maintainer }

        it 'shows correct items', :js do
          click_dropdown

          within_testid(selector) do
            expect(page).to have_content('Leave project')
            expect(page).to have_content("Copy project ID: #{project.id}")
            expect(page).to have_content('Project settings')
          end
        end
      end
    end

    context 'and the user is added to the group' do
      before do
        group.add_member(user, role)
        sign_in(user)
        visit project_path(project)
      end

      context 'and the user has developer access' do
        let_it_be(:role) { :developer }

        it 'shows correct items', :js do
          click_dropdown

          within_testid(selector) do
            expect(page).not_to have_content('Leave project')
            expect(page).to have_content("Copy project ID: #{project.id}")
            expect(page).not_to have_content('Project settings')
          end
        end
      end

      context 'and the user has maintainer access' do
        let_it_be(:role) { :maintainer }

        it 'shows correct items', :js do
          click_dropdown

          within_testid(selector) do
            expect(page).not_to have_content('Leave project')
            expect(page).to have_content("Copy project ID: #{project.id}")
            expect(page).to have_content('Project settings')
          end
        end
      end
    end
  end

  context 'when a user is not signed in' do
    before do
      visit project_path(project)
    end

    it 'shows correct items', :js do
      click_dropdown

      within_testid(selector) do
        expect(page).not_to have_content('Leave project')
        expect(page).to have_content("Copy project ID: #{project.id}")
        expect(page).not_to have_content('Project settings')
      end
    end
  end
end

def click_dropdown
  find_by_testid(selector).click
end
