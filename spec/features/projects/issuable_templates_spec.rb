# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'issuable templates', :js, feature_category: :team_planning do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:issue_form_location) { '#content-body .issuable-details .detail-page-description' }

  before do
    project.add_maintainer(user)
    sign_in user
  end

  context 'user creates an issue using templates' do
    let(:template_content) { 'this is a test "bug" template' }
    let(:longtemplate_content) { %(this\n\n\n\n\nis\n\n\n\n\na\n\n\n\n\nbug\n\n\n\n\ntemplate) }
    let(:issue) { create(:issue, author: user, assignees: [user], project: project) }
    let(:description_addition) { ' appending to description' }

    before do
      project.repository.create_file(
        user,
        '.gitlab/issue_templates/bug.md',
        template_content,
        message: 'added issue template',
        branch_name: 'master')
      project.repository.create_file(
        user,
        '.gitlab/issue_templates/test.md',
        longtemplate_content,
        message: 'added issue template',
        branch_name: 'master')
      visit project_issue_path project, issue
      page.find('.js-issuable-edit').click
      fill_in :'issuable-title', with: 'test issue title'
    end

    it 'user selects "bug" template' do
      select_template 'bug'
      wait_for_requests
      assert_template(page_part: issue_form_location)
      expect(page).to have_current_path(/issuable_template=bug/)
      save_changes
    end

    it 'user selects "bug" template and then "no template"' do
      select_template 'bug'
      wait_for_requests
      expect(page).to have_current_path(/issuable_template=bug/)
      select_option 'No template'
      wait_for_requests
      assert_template(expected_content: '', page_part: issue_form_location)
      expect(page).not_to have_current_path(/issuable_template=bug/)
      save_changes('')
    end

    it 'user selects "bug" template, edits description and then selects "reset template"' do
      select_template 'bug'
      wait_for_requests
      find_field('issue-description').send_keys(description_addition)
      assert_template(expected_content: template_content + description_addition, page_part: issue_form_location)
      select_option 'Reset template'
      assert_template(page_part: issue_form_location)
      save_changes
    end
  end

  context 'user creates an issue template using issuable_template query param' do
    let(:template_content) { 'this is a test "bug" template' }

    before do
      project.repository.create_file(
        user,
        '.gitlab/issue_templates/bug.md',
        template_content,
        message: 'added issue template',
        branch_name: 'master')
    end

    it 'applies correctly in the rich text editor' do
      visit new_project_issue_path project
      click_button "Switch to rich text editing"

      visit new_project_issue_path(project, { issuable_template: 'bug' })

      expect(page).to have_content(template_content)
    end
  end

  context 'user creates an issue using templates, with a prior description' do
    let(:prior_description) { 'test issue description' }
    let(:template_content) { 'this is a test "bug" template' }
    let(:issue) { create(:issue, author: user, assignees: [user], project: project) }

    before do
      project.repository.create_file(
        user,
        '.gitlab/issue_templates/bug.md',
        template_content,
        message: 'added issue template',
        branch_name: 'master')
      visit project_issue_path project, issue
      page.find('.js-issuable-edit').click
      fill_in :'issuable-title', with: 'test issue title'
      fill_in :'issue-description', with: prior_description
    end

    it 'user selects "bug" template' do
      select_template 'bug'
      wait_for_requests
      assert_template(page_part: issue_form_location)
      save_changes
    end
  end

  context 'user creates an issue with a default template from the repo' do
    let(:template_content) { 'this is the default template' }

    before do
      project.repository.create_file(
        user,
        '.gitlab/issue_templates/default.md',
        template_content,
        message: 'added default issue template',
        branch_name: 'master'
      )
    end

    it 'does not overwrite autosaved description' do
      visit new_project_issue_path project
      wait_for_requests

      assert_template # default template is loaded the first time

      fill_in 'issue_description', with: 'my own description', fill_options: { clear: :backspace }

      visit new_project_issue_path project
      wait_for_requests

      assert_template(expected_content: 'my own description')
    end
  end

  context 'user creates a merge request using templates' do
    let(:template_content) { 'this is a test "feature-proposal" template' }
    let(:bug_template_content) { 'this is merge request bug template' }
    let(:template_override_warning) { 'Applying a template will replace the existing issue description.' }
    let(:updated_description) { 'updated merge request description' }
    let(:merge_request) { create(:merge_request, source_project: project) }

    before do
      project.repository.create_file(
        user,
        '.gitlab/merge_request_templates/feature-proposal.md',
        template_content,
        message: 'added merge request template',
        branch_name: 'master')
      project.repository.create_file(
        user,
        '.gitlab/merge_request_templates/bug.md',
        bug_template_content,
        message: 'added merge request bug template',
        branch_name: 'master')
      visit edit_project_merge_request_path project, merge_request
      fill_in :'merge_request[title]', with: 'test merge request title'
    end

    it 'user selects "feature-proposal" template' do
      select_template 'feature-proposal'
      wait_for_requests
      assert_template
      save_changes
    end

    context 'changes template' do
      before do
        select_template 'bug'
        wait_for_requests
        fill_in :'merge_request[description]', with: updated_description
        select_template 'feature-proposal'
        expect(page).to have_content template_override_warning
      end

      it 'user selects "bug" template, then updates description, then selects "feature-proposal" template, then cancels template change' do
        page.find('.js-template-warning .js-close-btn.js-cancel-btn').click
        expect(find('textarea')['value']).to eq(updated_description)
        expect(page).not_to have_content template_override_warning
      end

      it 'user selects "bug" template, then updates description, then selects "feature-proposal" template, then dismiss the template warning' do
        page.find('.js-template-warning .js-close-btn.js-dismiss-btn').click
        expect(find('textarea')['value']).to eq(updated_description)
        expect(page).not_to have_content template_override_warning
      end

      it 'user selects "bug" template, then updates description, then selects "feature-proposal" template, then applies template change' do
        page.find('.js-template-warning .js-override-template').click
        wait_for_requests
        assert_template
      end
    end
  end

  context 'user creates a merge request from a forked project using templates' do
    let(:template_content) { 'this is a test "feature-proposal" template' }
    let(:fork_user) { create(:user) }
    let(:forked_project) { fork_project(project, fork_user, repository: true) }
    let(:merge_request) { create(:merge_request, source_project: forked_project, target_project: project) }

    before do
      sign_out(:user)

      project.add_developer(fork_user)

      sign_in(fork_user)

      project.repository.create_file(
        fork_user,
        '.gitlab/merge_request_templates/feature-proposal.md',
        template_content,
        message: 'added merge request template',
        branch_name: 'master')
      visit edit_project_merge_request_path project, merge_request
      fill_in :'merge_request[title]', with: 'test merge request title'
    end

    context 'feature proposal template' do
      context 'template exists in target project' do
        it 'user selects template' do
          select_template 'feature-proposal'
          wait_for_requests
          assert_template
          save_changes
        end
      end
    end
  end

  def assert_template(expected_content: template_content, page_part: '#content-body')
    page.within(page_part) do
      expect(find('textarea')['value']).to eq(expected_content)
    end
  end

  def save_changes(expected_content = template_content)
    click_button "Save changes"
    expect(page).to have_content expected_content
  end

  def select_template(name)
    find('.js-issuable-selector').click

    find('.js-issuable-selector-wrap .dropdown-content a', text: name, match: :first).click
  end

  def select_option(name)
    find('.js-issuable-selector').click

    find('.js-issuable-selector-wrap .dropdown-footer-list a', text: name, match: :first).click
  end
end
