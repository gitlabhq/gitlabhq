require 'spec_helper'

feature 'Contributions Calendar', js: true, feature: true do
  include WaitForAjax

  let(:contributed_project) { create(:project, :public) }

  before do
    login_as :user

    issue_params = { title: 'Bug in old browser' }
    Issues::CreateService.new(contributed_project, @user, issue_params).execute

    # Push code contribution
    push_params = {
      project: contributed_project,
      action: Event::PUSHED,
      author_id: @user.id,
      data: { commit_count: 3 }
    }

    Event.create(push_params)

    visit @user.username
    wait_for_ajax
  end

  it 'displays calendar', js: true do
    expect(page).to have_css('.js-contrib-calendar')
  end

  it 'displays calendar activity log', js: true do
    expect(find('.content_list .event-note')).to have_content "Bug in old browser"
  end

  it 'displays calendar activity square color', js: true do
    expect(page).to have_selector('.user-contrib-cell[fill=\'#acd5f2\']', count: 1)
  end
end
