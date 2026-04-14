# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User manages subscription', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(merge_request_path(merge_request))
  end

  it 'toggles subscription' do
    wait_for_requests

    find_by_testid('subscribe-button').click
    expect(page).to have_selector('svg.gl-animated-icon-on')

    find_by_testid('subscribe-button').click
    expect(page).to have_selector('svg.gl-animated-icon-off')
  end
end
