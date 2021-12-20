# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Blob shortcuts', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:issue) { create(:issue, project: project, author: user) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:note_text) { 'I got this!' }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  shared_examples "quotes the selected text" do
    it "quotes the selected text", :quarantine do
      select_element('.note-text')
      find('body').native.send_key('r')

      expect(find('.js-main-target-form .js-vue-comment-form').value).to include(note_text)
    end
  end

  describe 'pressing "r"' do
    describe 'On an Issue' do
      before do
        create(:note, noteable: issue, project: project, note: note_text)
        visit project_issue_path(project, issue)
        wait_for_requests
      end

      include_examples 'quotes the selected text'
    end

    describe 'On a Merge Request' do
      before do
        create(:note, noteable: merge_request, project: project, note: note_text)
        visit project_merge_request_path(project, merge_request)
        wait_for_requests
      end

      include_examples 'quotes the selected text'
    end
  end

  shared_examples "opens assignee dropdown for editing" do
    it "opens assignee dropdown for editing" do
      find('body').native.send_key('a')

      expect(find('.block.assignee')).to have_selector('.js-sidebar-assignee-data')
    end
  end

  describe 'pressing "a"' do
    describe 'On an Issue' do
      before do
        stub_feature_flags(issue_assignees_widget: false)
        visit project_issue_path(project, issue)
        wait_for_requests
      end

      include_examples 'opens assignee dropdown for editing'
    end

    describe 'On a Merge Request' do
      before do
        stub_feature_flags(issue_assignees_widget: false)
        visit project_merge_request_path(project, merge_request)
        wait_for_requests
      end

      include_examples 'opens assignee dropdown for editing'
    end
  end

  shared_examples "opens milestones dropdown for editing" do
    it "opens milestones dropdown for editing" do
      find('body').native.send_key('m')

      expect(find('[data-testid="milestone-edit"]')).to have_selector('.gl-new-dropdown-inner')
    end
  end

  describe 'pressing "m"' do
    describe 'On an Issue' do
      before do
        visit project_issue_path(project, issue)
        wait_for_requests
      end

      include_examples 'opens milestones dropdown for editing'
    end

    describe 'On a Merge Request' do
      before do
        visit project_merge_request_path(project, merge_request)
        wait_for_requests
      end

      include_examples 'opens milestones dropdown for editing'
    end
  end

  shared_examples "opens labels dropdown for editing" do
    it "opens labels dropdown for editing" do
      find('body').native.send_key('l')

      expect(find('.js-labels-block')).to have_selector('[data-testid="labels-select-dropdown-contents"]')
    end
  end

  describe 'pressing "l"' do
    describe 'On an Issue' do
      before do
        visit project_issue_path(project, issue)
        wait_for_requests
      end

      include_examples 'opens labels dropdown for editing'
    end

    describe 'On a Merge Request' do
      before do
        visit project_merge_request_path(project, merge_request)
        wait_for_requests
      end

      include_examples 'opens labels dropdown for editing'
    end
  end
end
