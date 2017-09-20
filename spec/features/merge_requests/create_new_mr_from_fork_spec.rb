require 'spec_helper'

feature 'Creating a merge request from a fork', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let!(:source_project) { ::Projects::ForkService.new(project, user).execute }

  before do
    source_project.add_master(user)

    sign_in(user)
  end

  shared_examples 'create merge request to other project' do
    it 'has all possible target projects' do
      visit project_new_merge_request_path(source_project)

      first('.js-target-project').click

      within('.dropdown-target-project .dropdown-content') do
        expect(page).to have_content(project.full_path)
        expect(page).to have_content(target_project.full_path)
        expect(page).to have_content(source_project.full_path)
      end
    end

    it 'allows creating the merge request to another target project' do
      visit project_merge_requests_path(source_project)

      page.within '.content' do
        click_link 'New merge request'
      end

      find('.js-source-branch', match: :first).click
      find('.dropdown-source-branch .dropdown-content a', match: :first).click

      first('.js-target-project').click
      find('.dropdown-target-project .dropdown-content a', text: target_project.full_path).click

      click_button 'Compare branches and continue'

      wait_for_requests

      expect { click_button 'Submit merge request' }
        .to change { target_project.merge_requests.reload.size }.by(1)
    end
  end

  context 'creating to the source of a fork' do
    let(:target_project) { project }

    it_behaves_like('create merge request to other project')
  end

  context 'creating to a sibling of a fork' do
    let!(:target_project) { ::Projects::ForkService.new(project, create(:user)).execute }

    it_behaves_like('create merge request to other project')
  end
end
