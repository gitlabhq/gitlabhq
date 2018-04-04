require 'rails_helper'

feature 'Profile > Account', :js do
  given(:user) { create(:user, username: 'foo') }

  before do
    sign_in(user)
  end

  describe 'Change username' do
    given(:new_username) { 'bar' }
    given(:new_user_path) { "/#{new_username}" }
    given(:old_user_path) { "/#{user.username}" }

    scenario 'the user is accessible via the new path' do
      update_username(new_username)
      visit new_user_path
      expect(current_path).to eq(new_user_path)
      expect(find('.user-info')).to have_content(new_username)
    end

    scenario 'the old user path redirects to the new path' do
      update_username(new_username)
      visit old_user_path
      expect(current_path).to eq(new_user_path)
      expect(find('.user-info')).to have_content(new_username)
    end

    context 'with a project' do
      given!(:project) { create(:project, namespace: user.namespace) }
      given(:new_project_path) { "/#{new_username}/#{project.path}" }
      given(:old_project_path) { "/#{user.username}/#{project.path}" }

      before(:context) do
        TestEnv.clean_test_path
      end

      after do
        TestEnv.clean_test_path
      end

      scenario 'the project is accessible via the new path' do
        update_username(new_username)
        visit new_project_path
        expect(current_path).to eq(new_project_path)
        expect(find('.breadcrumbs-sub-title')).to have_content('Details')
      end

      scenario 'the old project path redirects to the new path' do
        update_username(new_username)
        visit old_project_path
        expect(current_path).to eq(new_project_path)
        expect(find('.breadcrumbs-sub-title')).to have_content('Details')
      end
    end
  end
end

def update_username(new_username)
  allow(user.namespace).to receive(:move_dir)
  visit profile_account_path

  fill_in 'modal-username-change-input', with: new_username

  page.find('[data-target="#modal-username-change-confirmation"]').click

  page.within('.modal') do
    # Confirm modal, no better selector at the moment
    find('.btn-warning').click
  end
end
