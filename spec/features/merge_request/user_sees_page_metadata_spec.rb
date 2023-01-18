# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees page metadata', feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request, description: '**Lorem** _ipsum_ dolor sit [amet](https://example.com)') }
  let(:project) { merge_request.target_project }
  let(:user) { project.creator }

  before do
    project.add_maintainer(user)
    sign_in(user)
    visit project_merge_request_path(project, merge_request)
  end

  it_behaves_like 'page meta description', 'Lorem ipsum dolor sit amet'
end
