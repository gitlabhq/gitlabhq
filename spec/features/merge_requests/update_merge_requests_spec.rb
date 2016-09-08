require 'rails_helper'

feature 'Multiple merge requests updating from merge_requests#index', feature: true do
  include WaitForAjax

  let!(:user)    { create(:user)}
  let!(:project) { create(:project) }
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  before do
    project.team << [user, :master]
    login_as(user)
  end

  context 'status', js: true do
    it 'sets to closed' do
      visit namespace_project_merge_requests_path(project.namespace, project)

      change_status('Closed')
      expect(page).to have_selector('.merge-request', count: 0)
    end

    it 'sets to open' do
      merge_request.close
      visit namespace_project_merge_requests_path(project.namespace, project, state: 'closed')

      change_status('Open')
      expect(page).to have_selector('.merge-request', count: 0)
    end
  end

  context 'assignee', js: true do
    context 'set assignee' do
      before do
        visit namespace_project_merge_requests_path(project.namespace, project)
      end

      it "should update merge request with assignee" do
        change_assignee(user.name)

        page.within('.merge-request .controls') do
          expect(find('.author_link')["title"]).to have_content(user.name)
        end
      end
    end

    context 'remove assignee' do
      before do
        merge_request.assignee = user
        merge_request.save
        visit namespace_project_merge_requests_path(project.namespace, project)
      end

      it "should remove assignee from the merge request" do
        change_assignee('Unassigned')
        expect(find('.merge-request .controls')).not_to have_css('.author_link')
      end
    end
  end

  context 'milestone', js: true do
    let(:milestone)  { create(:milestone, project: project) }

    context 'set milestone' do
      before do
        visit namespace_project_merge_requests_path(project.namespace, project)
      end

      it "should update merge request with milestone" do
        change_milestone(milestone.title)
        expect(find('.merge-request')).to have_content milestone.title
      end
    end

    context 'unset milestone' do
      before do
        merge_request.milestone = milestone
        merge_request.save
        visit namespace_project_merge_requests_path(project.namespace, project)
      end

      it "should remove milestone from the merge request" do
        change_milestone("No Milestone")
        expect(find('.merge-request')).not_to have_content milestone.title
      end
    end
  end

  def change_status(text)
    find('#check_all_issues').click
    find('.js-issue-status').click
    find('.dropdown-menu-status a', text: text).click
    click_update_merge_requests_button
  end

  def change_assignee(text)
    find('#check_all_issues').click
    find('.js-update-assignee').click
    wait_for_ajax

    page.within '.dropdown-menu-user' do
      click_link text
    end

    click_update_merge_requests_button
  end

  def change_milestone(text)
    find('#check_all_issues').click
    find('.issues_bulk_update .js-milestone-select').click
    find('.dropdown-menu-milestone a', text: text).click
    click_update_merge_requests_button
  end

  def click_update_merge_requests_button
    find('.update_selected_issues').click
    wait_for_ajax
  end
end
