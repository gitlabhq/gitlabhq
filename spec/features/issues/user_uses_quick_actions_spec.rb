# frozen_string_literal: true

require 'rails_helper'

describe 'Issues > User uses quick actions', :js do
  include Spec::Support::Helpers::Features::NotesHelpers

  context "issuable common quick actions" do
    let(:new_url_opts) { {} }
    let(:maintainer) { create(:user) }
    let(:project) { create(:project, :public) }
    let!(:label_bug) { create(:label, project: project, title: 'bug') }
    let!(:label_feature) { create(:label, project: project, title: 'feature') }
    let!(:milestone) { create(:milestone, project: project, title: 'ASAP') }
    let(:issuable) { create(:issue, project: project) }
    let(:source_issuable) { create(:issue, project: project, milestone: milestone, labels: [label_bug, label_feature])}

    it_behaves_like 'assign quick action', :issue
    it_behaves_like 'unassign quick action', :issue
    it_behaves_like 'close quick action', :issue
    it_behaves_like 'reopen quick action', :issue
    it_behaves_like 'title quick action', :issue
    it_behaves_like 'todo quick action', :issue
    it_behaves_like 'done quick action', :issue
    it_behaves_like 'subscribe quick action', :issue
    it_behaves_like 'unsubscribe quick action', :issue
    it_behaves_like 'lock quick action', :issue
    it_behaves_like 'unlock quick action', :issue
    it_behaves_like 'milestone quick action', :issue
    it_behaves_like 'remove_milestone quick action', :issue
    it_behaves_like 'label quick action', :issue
    it_behaves_like 'unlabel quick action', :issue
    it_behaves_like 'relabel quick action', :issue
    it_behaves_like 'award quick action', :issue
    it_behaves_like 'estimate quick action', :issue
    it_behaves_like 'remove_estimate quick action', :issue
    it_behaves_like 'spend quick action', :issue
    it_behaves_like 'remove_time_spent quick action', :issue
    it_behaves_like 'shrug quick action', :issue
    it_behaves_like 'tableflip quick action', :issue
    it_behaves_like 'copy_metadata quick action', :issue
    it_behaves_like 'issuable time tracker', :issue
  end

  describe 'issue-only commands' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public, :repository) }
    let(:issue) { create(:issue, project: project, due_date: Date.new(2016, 8, 28)) }

    before do
      project.add_maintainer(user)
      sign_in(user)
      visit project_issue_path(project, issue)
      wait_for_all_requests
    end

    after do
      wait_for_requests
    end

    it_behaves_like 'confidential quick action'
    it_behaves_like 'remove_due_date quick action'
    it_behaves_like 'duplicate quick action'
    it_behaves_like 'create_merge_request quick action'
    it_behaves_like 'due quick action'
    it_behaves_like 'move quick action'
  end
end
