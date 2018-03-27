require 'spec_helper'

feature 'Groups > User sees users dropdowns in issuables list' do
  let(:entity) { create(:group) }
  let(:user_in_dropdown) { create(:user) }
  let!(:user_not_in_dropdown) { create(:user) }
  let!(:project) { create(:project, group: entity) }

  before do
    entity.add_developer(user_in_dropdown)
  end

  it_behaves_like 'issuable user dropdown behaviors' do
    let(:issuable) { create(:issue, project: project) }
    let(:issuables_path) { issues_group_path(entity) }
  end

  it_behaves_like 'issuable user dropdown behaviors' do
    let(:issuable) { create(:merge_request, source_project: project) }
    let(:issuables_path) { merge_requests_group_path(entity) }
  end
end
