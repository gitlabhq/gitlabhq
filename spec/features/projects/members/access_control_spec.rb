# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Access control', feature_category: :groups_and_projects do
  describe 'Leaving a project' do
    context 'when the user is the project owner' do
      let_it_be(:project) { create(:project, :repository) }

      before do
        sign_in(project.first_owner)
        visit project_path(project)
      end

      it 'does not show a "Leave project" link' do
        expect(page).to have_content(project.name)
        expect(page).not_to have_content 'Leave project'
      end
    end

    context 'when the user is a group member' do
      let_it_be(:user) { create(:user) }
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, :repository, namespace: group) }

      before_all do
        group.add_developer(user)
      end

      before do
        sign_in(user)
      end

      it 'does not show a "Leave project" link' do
        visit project_path(project)

        expect(page).to have_content(project.name)
        expect(page).not_to have_content 'Leave project'
      end

      it 'renders a flash message if attempting to leave by url', :js do
        visit project_path(project, leave: 1)

        expect(find_by_testid('alert-danger')).to have_content 'You do not have permission to leave this project'
      end
    end
  end

  describe 'Requesting access', :js do
    context 'when the user is the project owner' do
      let_it_be(:project) { create(:project, :repository) }

      before do
        sign_in(project.first_owner)
        visit project_path(project)
      end

      it 'does not show the "Request access" button' do
        find_by_testid('projects-list-item-actions').click

        expect(page).to have_content(project.name)
        expect(page).not_to have_content 'Request access'
      end
    end

    context 'when the user is a direct project member' do
      let_it_be(:member) { create(:user, :with_namespace) }
      let_it_be(:project) { create(:project, :repository) }

      before_all do
        project.add_developer(member)
      end

      before do
        sign_in(member)
        visit project_path(project)
      end

      it 'does not show the "Request access" button' do
        find_by_testid('projects-list-item-actions').click

        expect(page).to have_content(project.name)
        expect(page).not_to have_content 'Request access'
      end
    end

    context 'when the user is a group member' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, :repository, namespace: group) }

      %i[owner maintainer developer reporter guest].each do |role|
        context "with #{role} access" do
          let_it_be(:user) { create(:user) }

          before_all do
            group.public_send(:"add_#{role}", user)
          end

          before do
            sign_in(user)
            visit project_path(project)
          end

          it 'does not show the "Request access" button' do
            find_by_testid('projects-list-item-actions').click

            expect(page).to have_content(project.name)
            expect(page).not_to have_content 'Request access'
          end
        end
      end
    end

    context 'when the user is a group requester' do
      let_it_be(:user) { create(:user) }
      let_it_be(:owner) { create(:user) }
      let_it_be(:group) { create(:group, :public) }
      let_it_be(:project) { create(:project, :repository, :public, namespace: group) }

      let(:group_actions_dropdown) do
        find('#group-more-action-dropdown [data-testid="groups-list-item-actions"]')
      end

      before_all do
        group.add_owner(owner)
      end

      before do
        sign_in(user)
      end

      it 'does not show the "Request access" or "Withdraw access request" button' do
        visit group_path(group)

        group_actions_dropdown.click
        click_link 'Request access'

        expect(page).to have_content('Your request for access has been queued for review')

        visit project_path(project)
        find_by_testid('projects-list-item-actions').click

        expect(page).to have_content(project.name)
        expect(page).not_to have_content 'Request access'
        expect(page).not_to have_content 'Withdraw access request'
      end
    end
  end
end
