# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'IDE merge request', :js, feature_category: :web_ide do
  include CookieHelper

  let_it_be(:user) { create(:user, :no_super_sidebar) }
  let_it_be(:project) { create(:project, :public, :repository, namespace: user.namespace) }
  let_it_be(:merge_request) { create(:merge_request, :simple, source_project: project) }

  before do
    stub_feature_flags(vscode_web_ide: false)

    sign_in(user)

    set_cookie('new-actions-popover-viewed', 'true')

    visit(merge_request_path(merge_request))
  end

  it 'user opens merge request' do
    click_button 'Code'
    click_link 'Open in Web IDE'

    wait_for_requests

    expect(page).not_to have_selector('.monaco-diff-editor')
  end
end
