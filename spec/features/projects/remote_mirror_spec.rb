require 'spec_helper'

feature 'Project remote mirror', :feature do
  let(:project) { create(:project, :repository, :remote_mirror) }
  let(:remote_mirror) { project.remote_mirrors.first }
  let(:user) { create(:user) }

  describe 'On a project', :js do
    before do
      project.add_master(user)
      sign_in user
    end

    context 'when last_error is present but last_update_at is not' do
      it 'renders error message without timstamp' do
        remote_mirror.update_attributes(last_error: 'Some new error', last_update_at: nil)

        visit project_mirror_path(project)

        expect(page).to have_content('The remote repository failed to update.')
      end
    end

    context 'when last_error and last_update_at are present' do
      it 'renders error message with timestamp' do
        remote_mirror.update_attributes(last_error: 'Some new error', last_update_at: Time.now - 5.minutes)

        visit project_mirror_path(project)

        expect(page).to have_content('The remote repository failed to update 5 minutes ago.')
      end
    end
  end
end
