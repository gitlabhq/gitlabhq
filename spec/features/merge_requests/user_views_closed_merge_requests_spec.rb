# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views closed merge requests', :js, feature_category: :code_review_workflow do
  let!(:closed_merge_request) { create(:closed_merge_request, source_project: project, target_project: project) }
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:project) { create(:project, :public) }

  before do
    visit(project_merge_requests_path(project, state: :closed))
  end

  it 'shows closed merge requests' do
    expect(page).to have_content(closed_merge_request.title).and have_no_content(merge_request.title)
  end
end
