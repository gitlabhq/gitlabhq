# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Checklist drag and drop', :js, feature_category: :team_planning do
  let_it_be_with_refind(:project) { create(:project, :public) }

  let(:user)  { create(:user, :with_namespace) }
  let(:issue) { create(:issue, project: project, author: user) }

  before do
    issue.update!(description: "- [ ] First item\n- [ ] Second item\n- [ ] Third item")

    sign_in(user)
    visit project_issue_path(project, issue)
  end

  it 'renders the held clone with row styling and reorders on drop', :aggregate_failures do
    first_item = find('li.task-list-item', text: 'First item')
    first_item.hover
    grip = first_item.find('.drag-icon', visible: :all)

    page.driver.browser.action.move_to(grip.native, -9, 0).click_and_hold.perform
    8.times do
      page.driver.browser.action.move_by(0, 5).perform
      sleep 0.05
    end

    # Sortable re-parents its drag clone to <body>; drag start wraps it in a
    # shell carrying the row style scopes so the held row renders like the
    # row it copies.
    expect(page).to have_css(
      'body > .js-drag-clone-wrapper > ul.task-list > li.task-list-item.is-dragging'
    )
    expect(page).to have_css('li.task-list-item.is-ghost')

    page.driver.browser.action.release.perform

    expect(page).not_to have_css('.js-drag-clone-wrapper')
    expect(page).to have_css('.description ul.task-list > li.task-list-item', count: 3)
    expect(page).to have_css('.description ul.task-list', text: /Second item.*First item.*Third item/m)
  end
end
