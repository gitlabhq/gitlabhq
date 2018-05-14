require 'spec_helper'

describe 'Projects > Settings > For a forked project', :js do
  include ProjectForksHelper
  let(:user) { create(:user) }
  let(:original_project) { create(:project) }
  let(:forked_project) { fork_project(original_project, user) }

  before do
    original_project.add_master(user)
    forked_project.add_master(user)
    sign_in(user)
  end

  shared_examples 'project settings for a forked projects' do
    it 'allows deleting the link to the forked project' do
      visit edit_project_path(forked_project)

      click_button 'Remove fork relationship'

      wait_for_requests

      fill_in('confirm_name_input', with: forked_project.name)
      click_button('Confirm')

      expect(page).to have_content('The fork relationship has been removed.')
      expect(forked_project.reload.forked?).to be_falsy
    end
  end

  it_behaves_like 'project settings for a forked projects'

  context 'when the original project is deleted' do
    before do
      original_project.destroy!
    end

    it_behaves_like 'project settings for a forked projects'
  end
end
