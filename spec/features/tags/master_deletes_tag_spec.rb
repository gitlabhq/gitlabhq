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

      delete_tag 'v1.1.0'

      expect(page).not_to have_content 'v1.1.0'
    end
  end

  context 'from a specific tag page', :js do
    scenario 'deletes the tag' do
      click_on 'v1.0.0'
      expect(current_path).to eq(
        project_tag_path(project, 'v1.0.0'))

      delete_tag 'v1.0.0'

      expect(page).to have_content 'v1.1.0'
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
        delete_tag first('.ref-name').text

        expect(page).to have_content('Do not delete tags')
      end
    end

    context 'when Gitaly operation_user_delete_tag feature is disabled', :skip_gitaly_mock do
      before do
        allow_any_instance_of(Gitlab::Git::HooksService).to receive(:execute)
          .and_raise(Gitlab::Git::HooksService::PreReceiveError, 'Do not delete tags')
      end

      scenario 'shows the error message' do
        delete_tag first('.ref-name').text

        expect(page).to have_content('Do not delete tags')
      end
    end
  end

  def delete_tag(tag_name)
    find('#delete-tag-modal.modal', visible: false) # wait for Vue component to be loaded
    find(".js-delete-tag-button[data-tag-name=\"#{tag_name}\"]" % { tag_name: tag_name }).click

    page.within '#delete-tag-modal' do
      fill_in 'delete-tag-modal-input', with: tag_name
      click_on 'Delete tag'
    end
  end
end
