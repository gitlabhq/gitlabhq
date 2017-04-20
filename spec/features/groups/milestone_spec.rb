require 'rails_helper'

feature 'Group milestones', :feature, :js do
  let(:group) { create(:group) }
  let!(:project) { create(:project_empty_repo, group: group) }
  let(:user) { create(:group_member, :master, user: create(:user), group: group ).user }

  before do
    Timecop.freeze

    login_as(user)
  end

  after do
    Timecop.return
  end

  context 'create a milestone' do
    before do
      visit new_group_milestone_path(group)
    end

    it 'creates milestone with start date' do
      fill_in 'Title', with: 'testing'
      find('#milestone_start_date').click

      page.within(find('.pika-single')) do
        click_button '1'
      end

      click_button 'Create milestone'

      expect(find('.start_date')).to have_content(Date.today.at_beginning_of_month.strftime('%b %-d, %Y'))
    end
  end
end
