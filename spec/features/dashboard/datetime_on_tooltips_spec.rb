require 'spec_helper'

feature 'Tooltips on .timeago dates', :js do
  let(:user)            { create(:user) }
  let(:project)         { create(:project, name: 'test', namespace: user.namespace) }
  let(:created_date)    { Date.yesterday.to_time }
  let(:expected_format) { created_date.in_time_zone.strftime('%b %-d, %Y %l:%M%P') }

  context 'on the activity tab' do
    before do
      project.add_master(user)

      Event.create( project: project, author_id: user.id, action: Event::JOINED,
                    updated_at: created_date, created_at: created_date)

      sign_in user
      visit user_path(user)
      wait_for_requests()

      page.find('.js-timeago').hover
    end

    it 'has the datetime formated correctly' do
      expect(page).to have_selector('.local-timeago', text: expected_format)
    end
  end

  context 'on the snippets tab' do
    before do
      project.add_master(user)
      create(:snippet, author: user, updated_at: created_date, created_at: created_date)

      sign_in user
      visit user_snippets_path(user)
      wait_for_requests()

      page.find('.js-timeago.snippet-created-ago').hover
    end

    it 'has the datetime formated correctly' do
      expect(page).to have_selector('.local-timeago', text: expected_format)
    end
  end
end
