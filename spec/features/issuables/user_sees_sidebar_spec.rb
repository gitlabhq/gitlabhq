require 'rails_helper'

describe 'Issue Sidebar on Mobile' do
  include MobileHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:issue) { create(:issue, project: project) }
  let!(:user) { create(:user)}

  before do
    sign_in(user)
  end

  context 'mobile sidebar on merge requests', :js do
    before do
      visit project_merge_request_path(merge_request.project, merge_request)
    end

    it_behaves_like "issue sidebar stays collapsed on mobile"
  end

  context 'mobile sidebar on issues', :js do
    before do
      visit project_issue_path(project, issue)
    end

    it_behaves_like "issue sidebar stays collapsed on mobile"
  end
end
