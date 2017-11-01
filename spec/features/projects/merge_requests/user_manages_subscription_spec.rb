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
    subscribe_button = find('.js-issuable-subscribe-button')

    expect(subscribe_button).to have_content('Subscribe')

    click_on('Subscribe')

    wait_for_requests

    expect(subscribe_button).to have_content('Unsubscribe')

    click_on('Unsubscribe')

    wait_for_requests

    expect(subscribe_button).to have_content('Subscribe')
  end
end
