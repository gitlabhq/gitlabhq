# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views all merge requests', :js, feature_category: :code_review_workflow do
  let!(:closed_merge_request) { create(:closed_merge_request, source_project: project, target_project: project) }
  let!(:issue) { create(:issue, project: project) }
  let!(:merge_request) do
    create(:merge_request, source_project: project, target_project: project, title: "##{issue.iid} my title")
  end

  let(:project) { create(:project, :public) }

  before do
    visit(project_merge_requests_path(project, state: :all))
  end

  it 'shows all merge requests' do
    expect(page).to have_content(merge_request.title).and have_content(closed_merge_request.title)
  end

  it 'links to listed merge requests' do
    expect(page).to have_link(merge_request.title, href: /#{project_merge_request_path(project, merge_request)}$/)
    expect(page).to have_link(closed_merge_request.title,
      href: /#{project_merge_request_path(project, closed_merge_request)}$/)
  end
end
