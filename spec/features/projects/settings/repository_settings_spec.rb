require 'spec_helper'

feature 'Repository settings' do
  let(:project) { create(:project_empty_repo) }
  let(:user) { create(:user) }
  let(:role) { :developer }

  background do
    project.add_role(user, role)
    sign_in(user)
  end

  context 'for developer' do
    given(:role) { :developer }

    scenario 'is not allowed to view' do
      visit project_settings_repository_path(project)

      expect(page.status_code).to eq(404)
    end
  end

  context 'for master' do
    given(:role) { :master }

    context 'Deploy Keys', :js do
      let(:private_deploy_key) { create(:deploy_key, title: 'private_deploy_key', public: false) }
      let(:public_deploy_key) { create(:another_deploy_key, title: 'public_deploy_key', public: true) }
      let(:new_ssh_key) { attributes_for(:key)[:key] }

      scenario 'get list of keys' do
        project.deploy_keys << private_deploy_key
        project.deploy_keys << public_deploy_key

        visit project_settings_repository_path(project)

        expect(page).to have_content('private_deploy_key')
        expect(page).to have_content('public_deploy_key')
      end

      scenario 'add a new deploy key' do
        visit project_settings_repository_path(project)

        fill_in 'deploy_key_title', with: 'new_deploy_key'
        fill_in 'deploy_key_key', with: new_ssh_key
        check 'deploy_key_deploy_keys_projects_attributes_0_can_push'
        click_button 'Add key'

        expect(page).to have_content('new_deploy_key')
        expect(page).to have_content('Write access allowed')
      end

      scenario 'edit an existing deploy key' do
        project.deploy_keys << private_deploy_key
        visit project_settings_repository_path(project)

        find('li', text: private_deploy_key.title).click_link('Edit')

        fill_in 'deploy_key_title', with: 'updated_deploy_key'
        check 'deploy_key_deploy_keys_projects_attributes_0_can_push'
        click_button 'Save changes'

        expect(page).to have_content('updated_deploy_key')
        expect(page).to have_content('Write access allowed')
      end

      scenario 'edit a deploy key from projects user has access to' do
        project2 = create(:project_empty_repo)
        project2.add_role(user, role)
        project2.deploy_keys << private_deploy_key

        visit project_settings_repository_path(project)

        find('li', text: private_deploy_key.title).click_link('Edit')

        fill_in 'deploy_key_title', with: 'updated_deploy_key'
        click_button 'Save changes'

        expect(page).to have_content('updated_deploy_key')
      end

      scenario 'remove an existing deploy key' do
        project.deploy_keys << private_deploy_key
        visit project_settings_repository_path(project)

        accept_confirm { find('li', text: private_deploy_key.title).click_button('Remove') }

        expect(page).not_to have_content(private_deploy_key.title)
      end
    end

    context 'Deploy tokens' do
      let(:deploy_token) { create(:deploy_token, project: project, expires_at: Date.today + 2.days) }

      before do
        project.deploy_tokens << deploy_token
        visit project_settings_repository_path(project)
      end 

      scenario 'view deploy tokens' do
        within('.deploy-tokens') do
          expect(page).to have_content(deploy_token.name)
          expect(page).to have_content('In 1 day')
          expect(page).to have_content(deploy_token.scopes.join(", "))
        end
      end

      scenario 'add a new deploy token' do
        fill_in 'deploy_token_name', with: 'new_deploy_key'
        fill_in 'deploy_token_expires_at', with: (Date.today + 1.month).to_s
        check 'deploy_token_scopes_read_repo'
        check 'deploy_token_scopes_read_registry'
        click_button 'Create deploy token'

        expect(page).to have_content('Your new project deploy token has been created')
      end

      scenario 'revoke a deploy token', :js do
        within('.deploy-tokens') do
          click_link 'Revoke'
          click_link "Revoke #{deploy_token.name}"

          expect(page).not_to have_content(deploy_token.name)
          expect(page).not_to have_content('In 1 day')
          expect(page).not_to have_content(deploy_token.scopes.join(", "))
        end
      end
    end
  end
end
