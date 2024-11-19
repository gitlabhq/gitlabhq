# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin views hidden merge requests', :js, feature_category: :insider_threat do
  context 'when signed in as admin and viewing a hidden merge request' do
    let_it_be(:admin) { create(:admin) }
    let_it_be(:author) { create(:user, :banned) }
    let_it_be(:project) { create(:project) }
    let!(:merge_request) { create(:merge_request, source_project: project, author: author) }

    before do
      sign_in(admin)
      enable_admin_mode!(admin)
      visit(project_merge_requests_path(project))
    end

    it 'shows a hidden merge request icon' do
      page.within("#issuable_#{merge_request.id}") do
        tooltip = format(_('This %{issuable} is hidden because its author has been banned.'),
          issuable: _('merge request'))
        expect(page).to have_css("svg[title='#{tooltip}']")
        expect(page).to have_css('svg[data-testid="spam-icon"]')
      end
    end
  end
end
