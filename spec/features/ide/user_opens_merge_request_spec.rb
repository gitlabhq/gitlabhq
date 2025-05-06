# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'IDE merge request', :js, feature_category: :web_ide do
  include Features::WebIdeSpecHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository, namespace: user.namespace) }
  let_it_be(:merge_request) { create(:merge_request, :simple, source_project: project) }

  before do
    sign_in(user)

    visit(merge_request_path(merge_request))
  end

  it 'user opens merge request' do
    within '.merge-request' do
      click_button 'Code'
    end
    new_tab = window_opened_by { click_link 'Open in Web IDE' }

    switch_to_window new_tab

    wait_for_requests

    within_window new_tab do
      within_web_ide do
        expect(page).to have_css('a[aria-label^="Next Change"]')
      end
    end
  end
end
