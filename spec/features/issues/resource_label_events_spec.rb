# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'List issue resource label events', :js, feature_category: :team_planning do
  include ListboxHelpers

  let(:user)     { create(:user) }
  let(:project)  { create(:project, :public) }
  let(:issue)    { create(:issue, project: project, author: user) }
  let!(:label) { create(:label, project: project, title: 'foo') }
  let!(:user_status) { create(:user_status, user: user) }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
  end

  context 'when user displays the issue' do
    let!(:note)     { create(:note_on_issue, author: user, project: project, noteable: issue, note: 'some note') }
    let!(:event)    { create(:resource_label_event, user: user, issue: issue, label: label) }

    before do
      visit project_issue_path(project, issue)
    end

    it 'shows both notes and resource label events' do
      expect(page).to have_css('.note-comment', text: 'some note')
      expect(page).to have_css('.system-note', text: 'added foo label')
    end
  end

  context 'when user adds label to the issue' do
    before do
      create(:label, project: project, title: 'bar')
      project.add_developer(user)

      sign_in(user)
      visit project_issue_path(project, issue)
    end

    it 'shows add note for newly added labels' do
      within_testid('work-item-labels') do
        click_button 'Edit'
        select_listbox_item('foo')
        select_listbox_item('bar')
        send_keys(:escape)
      end

      expect(page).to have_css('.system-note', text: 'added bar foo labels')
    end
  end
end
