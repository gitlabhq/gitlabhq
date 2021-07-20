# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Settings > Access Tokens', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:bot_user) { create(:user, :project_bot) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  def create_project_access_token
    project.add_maintainer(bot_user)

    create(:personal_access_token, user: bot_user)
  end

  def active_project_access_tokens
    find('.table.active-tokens')
  end

  def no_project_access_tokens_message
    find('.settings-message')
  end

  def created_project_access_token
    find('#created-personal-access-token').value
  end

  context 'when user is not a project maintainer' do
    before do
      project.add_developer(user)
    end

    it 'does not show project access token page' do
      visit project_settings_access_tokens_path(project)

      expect(page).to have_content("Page Not Found")
    end
  end

  describe 'token creation' do
    it 'allows creation of a project access token' do
      name = 'My project access token'

      visit project_settings_access_tokens_path(project)
      fill_in 'Token name', with: name

      # Set date to 1st of next month
      find_field('Expiration date').click
      find('.pika-next').click
      click_on '1'

      # Scopes
      check 'api'
      check 'read_api'

      click_on 'Create project access token'

      expect(active_project_access_tokens).to have_text(name)
      expect(active_project_access_tokens).to have_text('In')
      expect(active_project_access_tokens).to have_text('api')
      expect(active_project_access_tokens).to have_text('read_api')
      expect(active_project_access_tokens).to have_text('Maintainer')
      expect(created_project_access_token).not_to be_empty
    end

    context 'when token creation is not allowed' do
      before do
        group.namespace_settings.update_column(:resource_access_token_creation_allowed, false)
      end

      it 'does not show project access token creation form' do
        visit project_settings_access_tokens_path(project)

        expect(page).not_to have_selector('#new_project_access_token')
      end

      it 'shows project access token creation disabled text' do
        visit project_settings_access_tokens_path(project)

        expect(page).to have_text('Project access token creation is disabled in this group. You can still use and manage existing tokens.')
      end

      context 'with a project in a personal namespace' do
        let(:personal_project) { create(:project) }

        before do
          personal_project.add_maintainer(user)
        end

        it 'shows project access token creation form and text' do
          visit project_settings_access_tokens_path(personal_project)

          expect(page).to have_selector('#new_project_access_token')
          expect(page).to have_text('Generate project access tokens scoped to this project for your applications that need access to the GitLab API.')
        end
      end

      context 'group settings link' do
        context 'when user is not a group owner' do
          before do
            group.add_developer(user)
          end

          it 'does not show group settings link' do
            visit project_settings_access_tokens_path(project)

            expect(page).not_to have_link('group settings', href: edit_group_path(group))
          end
        end

        context 'with nested groups' do
          let(:subgroup) { create(:group, parent: group) }

          context 'when user is not a top level group owner' do
            before do
              subgroup.add_owner(user)
            end

            it 'does not show group settings link' do
              visit project_settings_access_tokens_path(project)

              expect(page).not_to have_link('group settings', href: edit_group_path(group))
            end
          end
        end

        context 'when user is a group owner' do
          before do
            group.add_owner(user)
          end

          it 'shows group settings link' do
            visit project_settings_access_tokens_path(project)

            expect(page).to have_link('group settings', href: edit_group_path(group))
          end
        end
      end
    end
  end

  describe 'active tokens' do
    let!(:project_access_token) { create_project_access_token }

    it 'shows active project access tokens' do
      visit project_settings_access_tokens_path(project)

      expect(active_project_access_tokens).to have_text(project_access_token.name)
    end
  end

  describe 'inactive tokens' do
    let!(:project_access_token) { create_project_access_token }

    no_active_tokens_text = 'This project has no active access tokens.'

    it 'allows revocation of an active token' do
      visit project_settings_access_tokens_path(project)
      accept_confirm { click_on 'Revoke' }

      expect(page).to have_selector('.settings-message')
      expect(no_project_access_tokens_message).to have_text(no_active_tokens_text)
    end

    it 'removes expired tokens from active section' do
      project_access_token.update!(expires_at: 5.days.ago)
      visit project_settings_access_tokens_path(project)

      expect(page).to have_selector('.settings-message')
      expect(no_project_access_tokens_message).to have_text(no_active_tokens_text)
    end

    context 'when resource access token creation is not allowed' do
      before do
        group.namespace_settings.update_column(:resource_access_token_creation_allowed, false)
      end

      it 'allows revocation of an active token' do
        visit project_settings_access_tokens_path(project)
        accept_confirm { click_on 'Revoke' }

        expect(page).to have_selector('.settings-message')
        expect(no_project_access_tokens_message).to have_text(no_active_tokens_text)
      end
    end
  end
end
