# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request < User customizes merge commit message', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:issue_1) { create(:issue, project: project) }
  let(:issue_2) { create(:issue, project: project) }
  let(:source_branch) { 'csv' }
  let(:target_branch) { 'master' }
  let(:squash) { false }
  let(:merge_request) do
    create(
      :merge_request,
      source_project: project,
      target_project: project,
      source_branch: source_branch,
      target_branch: target_branch,
      description: "Description\n\nclosing #{issue_1.to_reference}, #{issue_2.to_reference}",
      squash: squash
    )
  end

  let(:merge_textbox) { page.find(:css, '#merge-message-edit', visible: false) }
  let(:squash_textbox) { page.find(:css, '#squash-message-edit', visible: false) }
  let(:default_merge_commit_message) do
    [
      "Merge branch '#{source_branch}' into '#{target_branch}'",
      merge_request.title,
      "Closes #{issue_1.to_reference} and #{issue_2.to_reference}",
      "See merge request #{merge_request.to_reference(full: true)}"
    ].join("\n\n")
  end

  before do
    project.add_maintainer(user)
    sign_in(user)
    visit project_merge_request_path(project, merge_request)
  end

  it 'has commit message without description' do
    expect(page).not_to have_selector('#merge-message-edit')
    find_by_testid('widget_edit_commit_message').click
    expect(merge_textbox).to be_visible
    expect(merge_textbox.value).to eq(default_merge_commit_message)
  end

  context 'when target project has merge commit template set' do
    let(:project) { create(:project, :public, :repository, merge_commit_template: '%{title}') }

    it 'uses merge commit template' do
      expect(page).not_to have_selector('#merge-message-edit')
      find_by_testid('widget_edit_commit_message').click
      expect(merge_textbox).to be_visible
      expect(merge_textbox.value).to eq(merge_request.title)
    end
  end

  context 'when squash is performed' do
    let(:squash) { true }

    it 'has default message with merge request title' do
      expect(page).not_to have_selector('#squash-message-edit')
      find_by_testid('widget_edit_commit_message').click
      expect(squash_textbox).to be_visible
      expect(merge_textbox).to be_visible
      expect(squash_textbox.value).to eq(merge_request.title)
      expect(merge_textbox.value).to eq(default_merge_commit_message)
    end

    context 'when target project has squash commit template set' do
      let(:project) { create(:project, :public, :repository, squash_commit_template: '%{description}') }

      it 'uses squash commit template' do
        expect(page).not_to have_selector('#squash-message-edit')
        find_by_testid('widget_edit_commit_message').click
        expect(squash_textbox).to be_visible
        expect(merge_textbox).to be_visible
        expect(squash_textbox.value).to eq(merge_request.description)
        expect(merge_textbox.value).to eq(default_merge_commit_message)
      end
    end
  end
end
