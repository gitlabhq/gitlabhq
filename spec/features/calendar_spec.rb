require 'spec_helper'

feature 'Contributions Calendar', :js do
  let(:user) { create(:user) }
  let(:contributed_project) { create(:project, :public, :repository) }
  let(:issue_note) { create(:note, project: contributed_project) }

  # Ex/ Sunday Jan 1, 2016
  date_format = '%A %b %-d, %Y'

  issue_title = 'Bug in old browser'
  issue_params = { title: issue_title }

  def get_cell_color_selector(contributions)
    activity_colors = ["#ededed", "rgb(172, 213, 242)", "rgb(127, 168, 201)", "rgb(82, 123, 160)", "rgb(37, 78, 119)"]
    # We currently don't actually test the cases with contributions >= 20
    activity_colors_index =
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

    ".user-contrib-cell[fill='#{activity_colors[activity_colors_index]}']"
  end

  def get_cell_date_selector(contributions, date)
    contribution_text =
      if contributions.zero?
        'No contributions'
      else
        "#{contributions} #{'contribution'.pluralize(contributions)}"
      end

    "#{get_cell_color_selector(contributions)}[data-original-title='#{contribution_text}<br />#{date}']"
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
      action: Event::COMMENTED,
      target: issue_note,
      author_id: user.id
    }

    Event.create(note_comment_params)
  end

  def selected_day_activities(visible: true)
    find('.user-calendar-activities', visible: visible).text
  end

  before do
    sign_in user
  end

  describe 'calendar day selection' do
    before do
      visit user.username
      wait_for_requests
    end

    it 'displays calendar' do
      expect(page).to have_css('.js-contrib-calendar')
    end

    describe 'select calendar day' do
      let(:cells) { page.all('.user-contrib-cell') }

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
        end

        it 'hides calendar day activities' do
          expect(selected_day_activities(visible: false)).to be_empty
        end
      end
    end
  end

  describe 'calendar daily activities' do
    shared_context 'visit user page' do
      before do
        visit user.username
        wait_for_requests
      end
    end

    shared_examples 'a day with activity' do |contribution_count:|
      include_context 'visit user page'

      it 'displays calendar activity square color for 1 contribution' do
        expect(page).to have_selector(get_cell_color_selector(contribution_count), count: 1)
      end

      it 'displays calendar activity square on the correct date' do
        today = Date.today.strftime(date_format)
        expect(page).to have_selector(get_cell_date_selector(contribution_count, today), count: 1)
      end
    end

    describe '1 issue creation calendar activity' do
      before do
        Issues::CreateService.new(contributed_project, user, issue_params).execute
      end

      it_behaves_like 'a day with activity', contribution_count: 1

      describe 'issue title is shown on activity page' do
        include_context 'visit user page'

        it 'displays calendar activity log' do
          expect(find('.content_list .event-note')).to have_content issue_title
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

        Timecop.freeze(Date.yesterday) do
          Issues::CreateService.new(contributed_project, user, issue_params).execute
        end
      end
      include_context 'visit user page'

      it 'displays calendar activity squares for both days' do
        expect(page).to have_selector(get_cell_color_selector(1), count: 2)
      end

      it 'displays calendar activity square for yesterday' do
        yesterday = Date.yesterday.strftime(date_format)
        expect(page).to have_selector(get_cell_date_selector(1, yesterday), count: 1)
      end

      it 'displays calendar activity square for today' do
        today = Date.today.strftime(date_format)
        expect(page).to have_selector(get_cell_date_selector(1, today), count: 1)
      end
    end
  end
end
