# frozen_string_literal: true

require 'spec_helper'

# These are written as feature specs because they cover more specific test scenarios
# than the ones described on spec/services/notes/create_service_spec.rb for quick actions,
# for example, adding quick actions when creating the issue and checking DateTime formats on UI.
# Because this kind of spec takes more time to run there is no need to add new ones
# for each existing quick action unless they test something not tested by existing tests.
RSpec.describe 'Issues > User uses quick actions', :js, feature_category: :team_planning do
  include Features::NotesHelpers

  before do
    allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(105)
  end

  context "issuable common quick actions" do
    let(:new_url_opts) { {} }
    let(:maintainer) { create(:user) }
    let_it_be(:project) { create(:project, :public) }
    let!(:label_bug) { create(:label, project: project, title: 'bug') }
    let!(:label_feature) { create(:label, project: project, title: 'feature') }
    let!(:milestone) { create(:milestone, project: project, title: 'ASAP') }
    let(:issuable) { create(:issue, project: project) }
    let(:source_issuable) { create(:issue, project: project, milestone: milestone, labels: [label_bug, label_feature]) }

    it_behaves_like 'close quick action', :issue
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

    it_behaves_like 'create_merge_request quick action'
    it_behaves_like 'move quick action'
    it_behaves_like 'zoom quick actions'
    it_behaves_like 'clone quick action'
    it_behaves_like 'promote_to_incident quick action'
  end
end
