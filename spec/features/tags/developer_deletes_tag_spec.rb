require 'spec_helper'

describe 'Developer deletes tag' do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, namespace: group) }

  before do
    project.add_developer(user)
    sign_in(user)
    visit project_tags_path(project)
  end

  context 'from the tags list page', :js do
    it 'deletes the tag' do
      expect(page).to have_content 'v1.1.0'

      delete_first_tag

      expect(page).not_to have_content 'v1.1.0'
    end
  end

  context 'from a specific tag page' do
    it 'deletes the tag' do
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
    before do
      allow_any_instance_of(Gitlab::GitalyClient::OperationService).to receive(:rm_tag)
        .and_raise(Gitlab::Git::PreReceiveError, 'GitLab: Do not delete tags')
    end

    it 'shows the error message' do
      delete_first_tag

      expect(page).to have_content('Do not delete tags')
    end
  end

  def delete_first_tag
    page.within('.content') do
      accept_confirm { first('.btn-remove').click }
    end
  end
end
