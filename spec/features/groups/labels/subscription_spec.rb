# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Labels subscription', feature_category: :team_planning do
  let(:user)     { create(:user) }
  let(:group)    { create(:group) }
  let!(:label1)  { create(:group_label, group: group, title: 'foo') }
  let!(:label2)  { create(:group_label, group: group, title: 'bar') }

  context 'when signed in' do
    before do
      group.add_developer(user)
      gitlab_sign_in user
    end

    it 'users can subscribe/unsubscribe to group labels', :js do
      visit group_labels_path(group)

      expect(page).to have_content(label1.title)

      within "#group_label_#{label1.id}" do
        expect(page).not_to have_button 'Unsubscribe'

        click_button 'Subscribe'

        expect(page).not_to have_button 'Subscribe'
        expect(page).to have_button 'Unsubscribe'

        click_button 'Unsubscribe'

        expect(page).to have_button 'Subscribe'
        expect(page).not_to have_button 'Unsubscribe'
      end
    end

    context 'subscription filter' do
      before do
        visit group_labels_path(group)
      end

      it 'shows only subscribed labels' do
        label1.subscribe(user)

        click_subscribed_tab

        page.within('.labels-container') do
          expect(page).to have_content label1.title
        end
      end

      it 'shows no subscribed labels message' do
        click_subscribed_tab

        page.within('.labels-container') do
          expect(page).not_to have_content label1.title
          expect(page).to have_content('You do not have any subscriptions yet')
        end
      end
    end
  end

  context 'when not signed in' do
    before do
      visit group_labels_path(group)
    end

    it 'users can not subscribe/unsubscribe to labels' do
      expect(page).to have_content label1.title
      expect(page).not_to have_button('Subscribe')
    end

    it 'does not show subscribed tab' do
      page.within('.gl-tabs-nav') do
        expect(page).not_to have_link 'Subscribed'
      end
    end
  end

  def click_link_on_dropdown(text)
    find('.dropdown-group-label').click

    page.within('.dropdown-group-label') do
      find('a.js-subscribe-button', text: text).click
    end
  end

  def click_subscribed_tab
    page.within('.gl-tabs-nav') do
      click_link 'Subscribed'
    end
  end
end
