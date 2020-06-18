# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'IDE merge request', :js do
  let(:merge_request) { create(:merge_request, :with_diffs, :simple, source_project: project) }
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.owner }

  before do
    sign_in(user)

    visit(merge_request_path(merge_request))
  end

  it 'user opens merge request' do
    click_link 'Open in Web IDE'

    wait_for_requests

    expect(page).to have_selector('.monaco-diff-editor')
  end
end
