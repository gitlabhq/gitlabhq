# frozen_string_literal: true

require 'rails_helper'

describe 'Merge request > User uses quick actions', :js do
  include Spec::Support::Helpers::Features::NotesHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:guest) { create(:user) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let!(:milestone) { create(:milestone, project: project, title: 'ASAP') }

  context "issuable common quick actions" do
    let!(:new_url_opts) { { merge_request: { source_branch: 'feature', target_branch: 'master' } } }
    let(:maintainer) { create(:user) }
    let(:project) { create(:project, :public, :repository) }
    let!(:label_bug) { create(:label, project: project, title: 'bug') }
    let!(:label_feature) { create(:label, project: project, title: 'feature') }
    let!(:milestone) { create(:milestone, project: project, title: 'ASAP') }
    let(:issuable) { create(:merge_request, source_project: project) }
    let(:source_issuable) { create(:issue, project: project, milestone: milestone, labels: [label_bug, label_feature])}

    it_behaves_like 'assign quick action', :merge_request
    it_behaves_like 'unassign quick action', :merge_request
    it_behaves_like 'close quick action', :merge_request
    it_behaves_like 'reopen quick action', :merge_request
    it_behaves_like 'title quick action', :merge_request
    it_behaves_like 'todo quick action', :merge_request
    it_behaves_like 'done quick action', :merge_request
    it_behaves_like 'subscribe quick action', :merge_request
    it_behaves_like 'unsubscribe quick action', :merge_request
    it_behaves_like 'lock quick action', :merge_request
    it_behaves_like 'unlock quick action', :merge_request
    it_behaves_like 'milestone quick action', :merge_request
    it_behaves_like 'remove_milestone quick action', :merge_request
    it_behaves_like 'label quick action', :merge_request
    it_behaves_like 'unlabel quick action', :merge_request
    it_behaves_like 'relabel quick action', :merge_request
    it_behaves_like 'award quick action', :merge_request
    it_behaves_like 'estimate quick action', :merge_request
    it_behaves_like 'remove_estimate quick action', :merge_request
    it_behaves_like 'spend quick action', :merge_request
    it_behaves_like 'remove_time_spent quick action', :merge_request
    it_behaves_like 'shrug quick action', :merge_request
    it_behaves_like 'tableflip quick action', :merge_request
    it_behaves_like 'copy_metadata quick action', :merge_request
    it_behaves_like 'issuable time tracker', :merge_request
  end

  describe 'merge-request-only commands' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let!(:milestone) { create(:milestone, project: project, title: 'ASAP') }

    before do
      project.add_maintainer(user)
    end

    it_behaves_like 'merge quick action'
    it_behaves_like 'target_branch quick action'
    it_behaves_like 'wip quick action'
  end
end
