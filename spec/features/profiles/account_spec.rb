# frozen_string_literal: true

require 'spec_helper'

describe 'Profile > Account', :js do
  let(:user) { create(:user, username: 'foo') }

  before do
    sign_in(user)
  end

  describe 'Change username' do
    let(:new_username) { 'bar' }
    let(:new_user_path) { "/#{new_username}" }
    let(:old_user_path) { "/#{user.username}" }

    it 'the user is accessible via the new path' do
      update_username(new_username)
      visit new_user_path
      expect(current_path).to eq(new_user_path)
      expect(find('.user-info')).to have_content(new_username)
    end

    it 'the old user path redirects to the new path' do
      update_username(new_username)
      visit old_user_path
      expect(current_path).to eq(new_user_path)
      expect(find('.user-info')).to have_content(new_username)
    end

    context 'with a project' do
      let!(:project) { create(:project, namespace: user.namespace) }
      let(:new_project_path) { "/#{new_username}/#{project.path}" }
      let(:old_project_path) { "/#{user.username}/#{project.path}" }

      before(:context) do
        TestEnv.clean_test_path
      end

      after do
        TestEnv.clean_test_path
      end

      it 'the project is accessible via the new path' do
        update_username(new_username)
        visit new_project_path
        expect(current_path).to eq(new_project_path)
        expect(find('.breadcrumbs-sub-title')).to have_content('Details')
      end

      it 'the old project path redirects to the new path' do
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

  fill_in 'username-change-input', with: new_username

  page.find('[data-target="#username-change-confirmation-modal"]').click

  page.within('.modal') do
    find('.js-modal-primary-action').click
  end

  wait_for_requests
end
