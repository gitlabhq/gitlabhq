# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Contributions Calendar', :js do
  include MobileHelpers

  let(:user) { create(:user) }
  let(:contributed_project) { create(:project, :public, :repository) }
  let(:issue_note) { create(:note, project: contributed_project) }

  # Ex/ Sunday Jan 1, 2016
  date_format = '%A %b %-d, %Y'

  issue_title = 'Bug in old browser'
  issue_params = { title: issue_title }

  def get_cell_level_selector(contributions)
    # We currently don't actually test the cases with contributions >= 20
    activity_level_index =
      if contributions > 0 && contributions < 10
        1
      elsif contributions >= 10 && contributions < 20
        2
      elsif contributions >= 20 && contributions < 30
        3
      elsif contributions >= 30
        4
      else
        0
      end

    ".user-contrib-cell:not(.contrib-legend)[data-level='#{activity_level_index}']"
  end

  def get_cell_date_selector(contributions, date)
    contribution_text =
      if contributions == 0
        'No contributions'
      else
        "#{contributions} #{'contribution'.pluralize(contributions)}"
      end

    "#{get_cell_level_selector(contributions)}[title='#{contribution_text}<br /><span class=\"gl-text-gray-300\">#{date}</span>']"
  end

  def push_code_contribution
    event = create(:push_event, project: contributed_project, author: user)

    create(:push_event_payload,
           event: event,
           commit_from: '11f9ac0a48b62cef25eedede4c1819964f08d5ce',
           commit_to: '1cf19a015df3523caf0a1f9d40c98a267d6a2fc2',
           commit_count: 3,
           ref: 'master')
  end

  def note_comment_contribution
    note_comment_params = {
      project: contributed_project,
      action: :commented,
      target: issue_note,
      author_id: user.id
    }

    Event.create!(note_comment_params)
  end

  def selected_day_activities(visible: true)
    find('#js-overview .user-calendar-activities', visible: visible).text
  end

  before do
    sign_in user
  end

  describe 'calendar day selection' do
    before do
      visit user.username
      page.find('.js-overview-tab a').click
      wait_for_requests
    end

    it 'displays calendar' do
      expect(find('#js-overview')).to have_css('.js-contrib-calendar')
    end

    describe 'select calendar day' do
      let(:cells) { page.all('#js-overview .user-contrib-cell') }

      before do
        cells[0].click
        wait_for_requests
        @first_day_activities = selected_day_activities
      end

      it 'displays calendar day activities' do
        expect(selected_day_activities).not_to be_empty
      end

      describe 'select another calendar day' do
        before do
          cells[1].click
          wait_for_requests
        end

        it 'displays different calendar day activities' do
          expect(selected_day_activities).not_to eq(@first_day_activities)
        end
      end

      describe 'deselect calendar day' do
        before do
          cells[0].click
          wait_for_requests
          cells[0].click
        end

        it 'hides calendar day activities' do
          expect(selected_day_activities(visible: false)).to be_empty
        end
      end
    end
  end

  shared_context 'visit user page' do
    before do
      visit user.username
      page.find('.js-overview-tab a').click
      wait_for_requests
    end
  end

  describe 'calendar daily activities' do
    shared_examples 'a day with activity' do |contribution_count:|
      include_context 'visit user page'

      it 'displays calendar activity square for 1 contribution', :sidekiq_might_not_need_inline do
        expect(find('#js-overview')).to have_selector(get_cell_level_selector(contribution_count), count: 1)

        today = Date.today.strftime(date_format)
        expect(find('#js-overview')).to have_selector(get_cell_date_selector(contribution_count, today), count: 1)
      end
    end

    describe '1 issue creation calendar activity' do
      before do
        Issues::CreateService.new(project: contributed_project, current_user: user, params: issue_params, spam_params: nil).execute
      end

      it_behaves_like 'a day with activity', contribution_count: 1

      describe 'issue title is shown on activity page' do
        include_context 'visit user page'

        it 'displays calendar activity log', :sidekiq_might_not_need_inline do
          expect(find('#js-overview .overview-content-list .event-target-title')).to have_content issue_title
        end
      end
    end

    describe '1 comment calendar activity' do
      before do
        note_comment_contribution
      end

      it_behaves_like 'a day with activity', contribution_count: 1
    end

    describe '10 calendar activities' do
      before do
        10.times { push_code_contribution }
      end

      it_behaves_like 'a day with activity', contribution_count: 10
    end

    describe 'calendar activity on two days' do
      before do
        push_code_contribution

        travel_to(Date.yesterday) do
          Issues::CreateService.new(project: contributed_project, current_user: user, params: issue_params, spam_params: nil).execute
        end
      end
      include_context 'visit user page'

      it 'displays calendar activity squares for both days', :sidekiq_might_not_need_inline do
        expect(find('#js-overview')).to have_selector(get_cell_level_selector(1), count: 2)
      end

      it 'displays calendar activity square for yesterday', :sidekiq_might_not_need_inline do
        yesterday = Date.yesterday.strftime(date_format)
        expect(find('#js-overview')).to have_selector(get_cell_date_selector(1, yesterday), count: 1)
      end

      it 'displays calendar activity square for today' do
        today = Date.today.strftime(date_format)
        expect(find('#js-overview')).to have_selector(get_cell_date_selector(1, today), count: 1)
      end
    end
  end

  describe 'on smaller screens' do
    shared_examples 'hidden activity calendar' do
      include_context 'visit user page'

      it 'hides the activity calender' do
        expect(find('#js-overview')).not_to have_css('.js-contrib-calendar')
      end
    end

    context 'size xs' do
      before do
        resize_screen_xs
      end

      it_behaves_like 'hidden activity calendar'
    end
  end
end
