require 'spec_helper'

feature 'Blob shortcuts', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:issue) { create(:issue, project: project, author: user) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:note_text) { 'I got this!' }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  shared_examples "quotes selected text" do
    select_element('.note-text')
    find('body').native.send_key('r')

    expect(find('.js-main-target-form .js-vue-comment-form').value).to include(note_text)
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
end
