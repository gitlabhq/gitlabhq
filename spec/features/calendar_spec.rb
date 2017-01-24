require 'spec_helper'

feature 'Contributions Calendar', js: true, feature: true do
  include WaitForAjax

  let(:contributed_project) { create(:project, :public) }

  # Ex/ Sunday Jan 1, 2016
  date_format = '%A %b %-d, %Y'

  issue_title = 'Bug in old browser'
  issue_params = { title: issue_title }

  def get_cell_color_selector(contributions)
    contribution_cell = '.user-contrib-cell'
    activity_colors = Array['#ededed', '#acd5f2', '#7fa8c9', '#527ba0', '#254e77']
    activity_colors_index = 0

    if contributions > 0 && contributions < 10
      activity_colors_index = 1
    elsif contributions >= 10 && contributions < 20
      activity_colors_index = 2
    elsif contributions >= 20 && contributions < 30
      activity_colors_index = 3
    elsif contributions >= 30
      activity_colors_index = 4
    end

    "#{contribution_cell}[fill='#{activity_colors[activity_colors_index]}']"
  end

  def get_cell_date_selector(contributions, date)
    contribution_text = 'No contributions'

    if contributions === 1
      contribution_text = '1 contribution'
    elsif contributions > 1
      contribution_text = "#{contributions} contributions"
    end

    "#{get_cell_color_selector(contributions)}[data-original-title='#{contribution_text}<br />#{date}']"
  end

  def push_code_contribution
    push_params = {
      project: contributed_project,
      action: Event::PUSHED,
      author_id: @user.id,
      data: { commit_count: 3 }
    }

    Event.create(push_params)
  end

  def get_first_cell_content
    find('.user-calendar-activities').text
  end

  before do
    login_as :user
    visit @user.username
    wait_for_ajax
  end

  it 'displays calendar', js: true do
    expect(page).to have_css('.js-contrib-calendar')
  end

  describe 'select calendar day', js: true do
    let(:cells) { page.all('.user-contrib-cell') }
    let(:first_cell_content_before) { get_first_cell_content }

    before do
      cells[0].click
      wait_for_ajax
      first_cell_content_before
    end

    it 'displays calendar day activities', js: true do
      expect(get_first_cell_content).not_to eq('')
    end

    describe 'select another calendar day', js: true do
      before do
        cells[1].click
        wait_for_ajax
      end

      it 'displays different calendar day activities', js: true do
        expect(get_first_cell_content).not_to eq(first_cell_content_before)
      end
    end

    describe 'deselect calendar day', js: true do
      before do
        cells[0].click
        wait_for_ajax
      end

      it 'hides calendar day activities', js: true do
        expect(get_first_cell_content).to eq('')
      end
    end
  end

  describe '1 calendar activity' do
    before do
      Issues::CreateService.new(contributed_project, @user, issue_params).execute
      visit @user.username
      wait_for_ajax
    end

    it 'displays calendar activity log', js: true do
      expect(find('.content_list .event-note')).to have_content issue_title
    end

    it 'displays calendar activity square color for 1 contribution', js: true do
      expect(page).to have_selector(get_cell_color_selector(1), count: 1)
    end

    it 'displays calendar activity square on the correct date', js: true do
      today = Date.today.strftime(date_format)
      expect(page).to have_selector(get_cell_date_selector(1, today), count: 1)
    end
  end

  describe '10 calendar activities' do
    before do
      (0..9).each do |i|
        push_code_contribution()
      end

      visit @user.username
      wait_for_ajax
    end

    it 'displays calendar activity square color for 10 contributions', js: true do
      expect(page).to have_selector(get_cell_color_selector(10), count: 1)
    end

    it 'displays calendar activity square on the correct date', js: true do
      today = Date.today.strftime(date_format)
      expect(page).to have_selector(get_cell_date_selector(10, today), count: 1)
    end
  end

  describe 'calendar activity on two days' do
    before do
      push_code_contribution()

      Timecop.freeze(Date.yesterday)
      Issues::CreateService.new(contributed_project, @user, issue_params).execute
      Timecop.return

      visit @user.username
      wait_for_ajax
    end

    it 'displays calendar activity squares for both days', js: true do
      expect(page).to have_selector(get_cell_color_selector(1), count: 2)
    end

    it 'displays calendar activity square for yesterday', js: true do
      yesterday = Date.yesterday.strftime(date_format)
      expect(page).to have_selector(get_cell_date_selector(1, yesterday), count: 1)
    end

    it 'displays calendar activity square for today', js: true do
      today = Date.today.strftime(date_format)
      expect(page).to have_selector(get_cell_date_selector(1, today), count: 1)
    end
  end
end
