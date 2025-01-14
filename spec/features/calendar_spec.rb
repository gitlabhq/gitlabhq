# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Contributions Calendar', :js, feature_category: :user_profile do
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

    "#{get_cell_level_selector(contributions)}[title='#{contribution_text}<br /><span class=\"gl-text-neutral-300\">#{date}</span>']"
  end

  def get_days_of_week
    page.all('[data-testid="user-contrib-cell-group"]')[1]
      .all('[data-testid="user-contrib-cell"]')
      .map do |node|
        node[:title].match(/(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)/)[0]
      end
  end

  def push_code_contribution
    event = create(:push_event, project: contributed_project, author: user)

    create(
      :push_event_payload,
      event: event,
      commit_from: '11f9ac0a48b62cef25eedede4c1819964f08d5ce',
      commit_to: '1cf19a015df3523caf0a1f9d40c98a267d6a2fc2',
      commit_count: 3,
      ref: 'master'
    )
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
    find('#js-legacy-tabs-container .user-calendar-activities', visible: visible).text
  end

  def recent_activities(visible: true)
    find_by_testid('user-activity-content', visible: visible)
  end

  shared_context 'when user page is visited' do
    before do
      visit user.username
      wait_for_requests
    end
  end

  context 'with `profile_tabs_vue` feature flag disabled' do
    before do
      stub_feature_flags(profile_tabs_vue: false)
      sign_in user
    end

    describe 'calendar day selection' do
      include_context 'when user page is visited'

      it 'displays calendar' do
        expect(find('#js-legacy-tabs-container')).to have_css('.js-contrib-calendar')
      end

      describe 'select calendar day' do
        let(:cells) { page.all('#js-legacy-tabs-container .user-contrib-cell') }

        before do
          cells[0].click
          wait_for_requests
        end

        it 'displays calendar day activities' do
          expect(selected_day_activities).not_to be_empty
        end

        it 'hides recent activities' do
          expect(recent_activities(visible: false)).not_to be_visible
        end

        describe 'select another calendar day' do
          it 'displays different calendar day activities' do
            first_day_activities = selected_day_activities

            cells[1].click
            wait_for_requests

            expect(selected_day_activities).not_to eq(first_day_activities)
          end
        end

        describe 'deselect calendar day' do
          before do
            cells[0].click
          end

          it 'hides calendar day activities' do
            expect(selected_day_activities(visible: false)).to be_empty
          end

          it 'shows recent activities' do
            expect(recent_activities).to be_visible
          end
        end
      end
    end

    describe 'calendar daily activities' do
      shared_examples 'a day with activity' do |contribution_count:|
        include_context 'when user page is visited'

        it 'displays calendar activity square for 1 contribution', :sidekiq_inline do
          expect(find('#js-legacy-tabs-container')).to have_selector(get_cell_level_selector(contribution_count), count: 1)

          today = Date.today.strftime(date_format)
          expect(find('#js-legacy-tabs-container')).to have_selector(get_cell_date_selector(contribution_count, today), count: 1)
        end
      end

      describe '1 issue and 1 work item creation calendar activity' do
        before do
          Issues::CreateService.new(
            container: contributed_project,
            current_user: user,
            params: issue_params
          ).execute
          WorkItems::CreateService.new(
            container: contributed_project,
            current_user: user,
            params: { title: 'new task' }
          ).execute
        end

        it_behaves_like 'a day with activity', contribution_count: 2

        describe 'issue title is shown on activity page' do
          include_context 'when user page is visited'

          it 'displays calendar activity log', :sidekiq_inline do
            expect(all('#js-legacy-tabs-container .overview-content-list .event-target-title').map(&:text)).to contain_exactly(
              match(/#{issue_title}/),
              match(/new task/)
            )
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
            Issues::CreateService.new(
              container: contributed_project,
              current_user: user,
              params: issue_params
            ).execute
          end
        end

        include_context 'when user page is visited'

        it 'displays calendar activity squares for both days', :sidekiq_inline do
          expect(find('#js-legacy-tabs-container')).to have_selector(get_cell_level_selector(1), count: 2)
        end

        it 'displays calendar activity square for yesterday', :sidekiq_inline do
          yesterday = Date.yesterday.strftime(date_format)
          expect(find('#js-legacy-tabs-container')).to have_selector(get_cell_date_selector(1, yesterday), count: 1)
        end

        it 'displays calendar activity square for today' do
          today = Date.today.strftime(date_format)
          expect(find('#js-legacy-tabs-container')).to have_selector(get_cell_date_selector(1, today), count: 1)
        end
      end
    end

    describe 'first_day_of_week setting' do
      context 'when first day of the week is set to Monday' do
        before do
          stub_application_setting(first_day_of_week: 1)
        end

        include_context 'when user page is visited'

        it 'shows calendar with Monday as the first day of the week' do
          expect(get_days_of_week).to eq(%w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday])
        end
      end

      context 'when first day of the week is set to Sunday' do
        before do
          stub_application_setting(first_day_of_week: 0)
        end

        include_context 'when user page is visited'

        it 'shows calendar with Sunday as the first day of the week' do
          expect(get_days_of_week).to eq(%w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday])
        end
      end
    end
  end

  context 'with `profile_tabs_vue` feature flag enabled' do
    before do
      sign_in user
    end

    include_context 'when user page is visited'

    it 'displays calendar' do
      expect(page).to have_css('[data-testid="contrib-calendar"]')
    end

    describe 'calendar daily activities' do
      shared_examples 'a day with activity' do |contribution_count:|
        include_context 'when user page is visited'

        it 'displays calendar activity square for 1 contribution', :sidekiq_inline do
          expect(page).to have_selector(get_cell_level_selector(contribution_count), count: 1)

          today = Date.today.strftime(date_format)
          expect(page).to have_selector(get_cell_date_selector(contribution_count, today), count: 1)
        end
      end

      describe '1 issue and 1 work item creation calendar activity' do
        before do
          Issues::CreateService.new(
            container: contributed_project,
            current_user: user,
            params: issue_params
          ).execute
          WorkItems::CreateService.new(
            container: contributed_project,
            current_user: user,
            params: { title: 'new task' }
          ).execute
        end

        it_behaves_like 'a day with activity', contribution_count: 2
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
            Issues::CreateService.new(
              container: contributed_project,
              current_user: user,
              params: issue_params
            ).execute
          end
        end

        include_context 'when user page is visited'

        it 'displays calendar activity squares for both days', :sidekiq_inline do
          expect(page).to have_selector(get_cell_level_selector(1), count: 2)
        end

        it 'displays calendar activity square for yesterday', :sidekiq_inline do
          yesterday = Date.yesterday.strftime(date_format)
          expect(page).to have_selector(get_cell_date_selector(1, yesterday), count: 1)
        end

        it 'displays calendar activity square for today' do
          today = Date.today.strftime(date_format)
          expect(page).to have_selector(get_cell_date_selector(1, today), count: 1)
        end
      end
    end

    describe 'first_day_of_week setting' do
      context 'when first day of the week is set to Monday' do
        before do
          stub_application_setting(first_day_of_week: 1)
        end

        include_context 'when user page is visited'

        it 'shows calendar with Monday as the first day of the week' do
          expect(get_days_of_week).to eq(%w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday])
        end
      end

      context 'when first day of the week is set to Sunday' do
        before do
          stub_application_setting(first_day_of_week: 0)
        end

        include_context 'when user page is visited'

        it 'shows calendar with Sunday as the first day of the week' do
          expect(get_days_of_week).to eq(%w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday])
        end
      end
    end
  end
end
