# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User clicks on merge request tabs', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  it 'adds entry to page history' do
    visit('/')
    visit(merge_request_path(merge_request))
    click_link('Changes')

    expect(current_url).to match(/diffs$/)

    page.driver.go_back

    expect(current_url).to match(merge_request_path(merge_request))

    page.driver.go_back

    expect(current_url).to match('/')
  end
end
