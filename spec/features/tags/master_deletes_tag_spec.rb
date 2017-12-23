require 'spec_helper'

feature 'Master deletes tag' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  before do
    project.add_master(user)
    sign_in(user)
    visit project_tags_path(project)
  end

  context 'from the tags list page', :js do
    scenario 'deletes the tag' do
      expect(page).to have_content 'v1.1.0'

      delete_first_tag

      expect(page).not_to have_content 'v1.1.0'
    end
  end

  context 'from a specific tag page' do
    scenario 'deletes the tag' do
      click_on 'v1.0.0'
      expect(current_path).to eq(
        project_tag_path(project, 'v1.0.0'))

      click_on 'Delete tag'

      expect(current_path).to eq(
        project_tags_path(project))
      expect(page).not_to have_content 'v1.0.0'
    end
  end

  context 'when pre-receive hook fails', :js do
    context 'when Gitaly operation_user_delete_tag feature is enabled' do
      before do
        allow_any_instance_of(Gitlab::GitalyClient::OperationService).to receive(:rm_tag)
          .and_raise(Gitlab::Git::HooksService::PreReceiveError, 'Do not delete tags')
      end

      scenario 'shows the error message' do
        delete_first_tag

        expect(page).to have_content('Do not delete tags')
      end
    end

    context 'when Gitaly operation_user_delete_tag feature is disabled', :skip_gitaly_mock do
      before do
        allow_any_instance_of(Gitlab::Git::HooksService).to receive(:execute)
          .and_raise(Gitlab::Git::HooksService::PreReceiveError, 'Do not delete tags')
      end

      scenario 'shows the error message' do
        delete_first_tag

        expect(page).to have_content('Do not delete tags')
      end
    end
  end

  def delete_first_tag
    page.within('.content') do
      accept_confirm { first('.btn-remove').click }
    end
  end
end
