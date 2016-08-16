require 'spec_helper'

feature 'issuable templates', feature: true, js: true do
  include WaitForAjax

  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  before do
    project.team << [user, :master]
    login_as user
  end

  context 'user creates an issue using templates' do
    let(:template_content) { 'this is a test "bug" template' }
    let(:issue) { create(:issue, author: user, assignee: user, project: project) }

    background do
      project.repository.commit_file(user, '.gitlab/issue_templates/bug.md', template_content, 'added issue template', 'master', false)
      visit edit_namespace_project_issue_path project.namespace, project, issue
      fill_in :'issue[title]', with: 'test issue title'
    end

    scenario 'user selects "bug" template' do
      select_template 'bug'
      wait_for_ajax
      preview_template
      save_changes
    end
  end

  context 'user creates a merge request using templates' do
    let(:template_content) { 'this is a test "feature-proposal" template' }
    let(:merge_request) { create(:merge_request, :with_diffs, source_project: project) }

    background do
      project.repository.commit_file(user, '.gitlab/merge_request_templates/feature-proposal.md', template_content, 'added merge request template', 'master', false)
      visit edit_namespace_project_merge_request_path project.namespace, project, merge_request
      fill_in :'merge_request[title]', with: 'test merge request title'
    end

    scenario 'user selects "feature-proposal" template' do
      select_template 'feature-proposal'
      wait_for_ajax
      preview_template
      save_changes
    end
  end

  context 'user creates a merge request from a forked project using templates' do
    let(:template_content) { 'this is a test "feature-proposal" template' }
    let(:fork_user) { create(:user) }
    let(:fork_project) { create(:project, :public) }
    let(:merge_request) { create(:merge_request, :with_diffs, source_project: fork_project) }

    background do
      logout
      project.team << [fork_user, :developer]
      fork_project.team << [fork_user, :master]
      create(:forked_project_link, forked_to_project: fork_project, forked_from_project: project)
      login_as fork_user
      fork_project.repository.commit_file(fork_user, '.gitlab/merge_request_templates/feature-proposal.md', template_content, 'added merge request template', 'master', false)
      visit edit_namespace_project_merge_request_path fork_project.namespace, fork_project, merge_request
      fill_in :'merge_request[title]', with: 'test merge request title'
    end

    scenario 'user selects "feature-proposal" template' do
      select_template 'feature-proposal'
      wait_for_ajax
      preview_template
      save_changes
    end
  end

  def preview_template
    click_link 'Preview'
    expect(page).to have_content template_content
  end

  def save_changes
    click_button "Save changes"
    expect(page).to have_content template_content
  end

  def select_template(name)
    first('.js-issuable-selector').click
    first('.js-issuable-selector-wrap .dropdown-content a', text: name).click
  end
end
