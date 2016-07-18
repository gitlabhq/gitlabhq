require 'rails_helper'

describe 'New/edit merge request', feature: true, js: true do
  let!(:project)   { create(:project, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
  let(:fork_project) { create(:project, forked_from_project: project) }
  let!(:user)      { create(:user)}
  let!(:milestone) { create(:milestone, project: project) }
  let!(:label)     { create(:label, project: project) }
  let!(:label2)    { create(:label, project: project) }

  before do
    project.team << [user, :master]
  end

  context 'owned projects' do
    before do
      merge_request = create(:merge_request,
                               source_project: project,
                               target_project: project,
                               source_branch: 'fix',
                               target_branch: 'master'
                              )

      login_as(user)

      visit edit_namespace_project_merge_request_path(project.namespace, project, merge_request)
    end

    it 'should update merge request' do
      update_merge_request
    end
  end

  context 'forked project' do
    before do
      fork_project.team << [user, :master]

      merge_request = create(:merge_request,
                               source_project: fork_project,
                               target_project: project,
                               source_branch: 'fix',
                               target_branch: 'master'
                              )

      login_as(user)

      visit edit_namespace_project_merge_request_path(project.namespace, project, merge_request)
    end

    it 'should update merge request' do
      update_merge_request
    end
  end

  def update_merge_request
    click_button 'Assignee'
    click_link user.name

    page.find '.js-assignee-search' do
      expect(page).to have_content user.name
    end

    click_button 'Milestone'
    click_link milestone.title

    page.find '.js-milestone-select' do
      expect(page).to have_content milestone.title
    end

    click_button 'Labels'
    click_link label.title
    click_link label2.title

    page.find '.js-label-select' do
      expect(page).to have_content label2.title
    end

    click_button 'Save changes'

    page.find '.issuable-sidebar' do
      expect(page).to have_content user.name
      expect(page).to have_content milestone.title
      expect(page).to have_content label.title
      expect(page).to have_content label2.title
    end
  end
end
