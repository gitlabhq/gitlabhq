# frozen_string_literal: true

require 'spec_helper'

# These are written as feature specs because they cover more specific test scenarios
# than the ones described on spec/services/notes/create_service_spec.rb for quick actions,
# for example, adding quick actions when creating the issue and checking DateTime formats on UI.
# Because this kind of spec takes more time to run there is no need to add new ones
# for each existing quick action unless they test something not tested by existing tests.
RSpec.describe 'Merge request > User uses quick actions', :js, :use_clean_rails_redis_caching,
  feature_category: :code_review_workflow do
  include Features::NotesHelpers

  context "issuable common quick actions" do
    let!(:new_url_opts) { { merge_request: { source_branch: 'feature', target_branch: 'master' } } }
    let(:maintainer) { create(:user) }
    let(:project) { create(:project, :public, :repository) }
    let!(:label_bug) { create(:label, project: project, title: 'bug') }
    let!(:label_feature) { create(:label, project: project, title: 'feature') }
    let!(:milestone) { create(:milestone, project: project, title: 'ASAP') }
    let(:issuable) { create(:merge_request, source_project: project) }
    let(:source_issuable) { create(:issue, project: project, milestone: milestone, labels: [label_bug, label_feature]) }

    it_behaves_like 'close quick action', :merge_request
    it_behaves_like 'issuable time tracker', :merge_request
  end

  describe 'merge-request-only commands' do
    let(:user) { create(:user) }
    let(:guest) { create(:user) }
    let(:project) { create(:project, :public, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let!(:milestone) { create(:milestone, project: project, title: 'ASAP') }

    before do
      project.add_maintainer(user)
    end

    it_behaves_like 'merge quick action'
    it_behaves_like 'rebase quick action'
  end
end
