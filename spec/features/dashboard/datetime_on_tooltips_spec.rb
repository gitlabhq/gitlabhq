# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Tooltips on .timeago dates', :js do
  let_it_be(:user)      { create(:user) }
  let_it_be(:project)   { create(:project, name: 'test', namespace: user.namespace) }

  let(:created_date)    { 1.day.ago.beginning_of_minute - 1.hour }

  before_all do
    project.add_maintainer(user)
  end

  context 'on the activity tab' do
    before do
      Event.create!( project: project, author_id: user.id, action: :joined,
                    updated_at: created_date, created_at: created_date)

      sign_in user
      visit user_activity_path(user)
      wait_for_requests
    end

    it 'has the datetime formated correctly' do
      expect(page).to have_selector('.js-timeago', text: '1 day ago')

      page.find('.js-timeago').hover

      expect(datetime_in_tooltip).to eq(created_date)
    end
  end

  context 'on the snippets tab' do
    before do
      create(:snippet, author: user, updated_at: created_date, created_at: created_date)

      sign_in user
      visit user_snippets_path(user)
      wait_for_requests
    end

    it 'has the datetime formated correctly' do
      expect(page).to have_selector('.js-timeago.snippet-created-ago', text: '1 day ago')

      page.find('.js-timeago.snippet-created-ago').hover

      expect(datetime_in_tooltip).to eq(created_date)
    end
  end

  def datetime_in_tooltip
    datetime_text = page.find('.tooltip').text
    DateTime.parse(datetime_text)
  end
end
