# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New merge request breadcrumb', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :repository) }
  let(:user) { project.creator }

  before do
    sign_in(user)
    visit(project_new_merge_request_path(project))
  end

  it 'displays link to project merge requests and new merge request' do
    within_testid 'breadcrumb-links' do
      expect(find_link('Merge requests')[:href]).to end_with(project_merge_requests_path(project))
      expect(find_link('New')[:href]).to end_with(project_new_merge_request_path(project))
    end
  end
end
