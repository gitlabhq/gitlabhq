# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'IDE merge request', :js, feature_category: :web_ide do
  let(:merge_request) { create(:merge_request, :simple, source_project: project) }
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.first_owner }

  before do
    stub_feature_flags(vscode_web_ide: false)

    sign_in(user)

    visit(merge_request_path(merge_request))
  end

  it 'user opens merge request' do
    click_button 'Code'
    click_link 'Open in Web IDE'

    wait_for_requests

    expect(page).not_to have_selector('.monaco-diff-editor')
  end
end
