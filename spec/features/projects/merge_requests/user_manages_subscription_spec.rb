require 'spec_helper'

describe 'User manages subscription', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(merge_request_path(merge_request))
  end

  it 'toggles subscription' do
    page.within('.js-issuable-subscribe-button') do
      expect(page).to have_css 'button:not(.is-checked)'
      find('button:not(.is-checked)').click

      wait_for_requests

      expect(page).to have_css 'button.is-checked'
      find('button.is-checked').click

      wait_for_requests

      expect(page).to have_css 'button:not(.is-checked)'
    end
  end
end
