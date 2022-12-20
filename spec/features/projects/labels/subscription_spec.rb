# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Labels subscription', feature_category: :team_planning do
  let(:user)     { create(:user) }
  let(:group)    { create(:group) }
  let(:project)  { create(:project, :public, namespace: group) }
  let!(:bug)     { create(:label, project: project, title: 'bug') }
  let!(:feature) { create(:group_label, group: group, title: 'feature') }

  context 'when signed in' do
    before do
      project.add_developer(user)
      sign_in user
    end

    it 'users can subscribe/unsubscribe to labels', :js do
      visit project_labels_path(project)

      expect(page).to have_content('bug')
      expect(page).to have_content('feature')

      within "#project_label_#{bug.id}" do
        expect(page).not_to have_button 'Unsubscribe'

        click_button 'Subscribe'

        expect(page).not_to have_button 'Subscribe'
        expect(page).to have_button 'Unsubscribe'

        click_button 'Unsubscribe'

        expect(page).to have_button 'Subscribe'
        expect(page).not_to have_button 'Unsubscribe'
      end

      within "#group_label_#{feature.id}" do
        expect(page).not_to have_button 'Unsubscribe'

        click_link_on_dropdown('Subscribe at group level')

        expect(page).not_to have_selector('.dropdown-group-label')
        expect(page).to have_button 'Unsubscribe'

        click_button 'Unsubscribe'

        expect(page).to have_selector('.dropdown-group-label')

        click_link_on_dropdown('Subscribe at project level')

        expect(page).not_to have_selector('.dropdown-group-label')
        expect(page).to have_button 'Unsubscribe'
      end
    end
  end

  context 'when not signed in' do
    it 'users can not subscribe/unsubscribe to labels' do
      visit project_labels_path(project)

      expect(page).to have_content 'bug'
      expect(page).to have_content 'feature'
      expect(page).not_to have_button('Subscribe')
      expect(page).not_to have_selector('.dropdown-group-label')
    end
  end

  def click_link_on_dropdown(text)
    find('.dropdown-group-label').click

    page.within('.dropdown-group-label') do
      find('.js-subscribe-button', text: text).click
    end
  end
end
