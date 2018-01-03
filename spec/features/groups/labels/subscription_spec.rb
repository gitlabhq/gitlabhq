require 'spec_helper'

feature 'Labels subscription' do
  let(:user)     { create(:user) }
  let(:group)    { create(:group) }
  let!(:feature) { create(:group_label, group: group, title: 'feature') }

  context 'when signed in' do
    before do
      group.add_developer(user)
      gitlab_sign_in user
    end

    scenario 'users can subscribe/unsubscribe to group labels', :js do
      visit group_labels_path(group)

      expect(page).to have_content('feature')

      within "#group_label_#{feature.id}" do
        expect(page).not_to have_button 'Unsubscribe'

        click_button 'Subscribe'

        expect(page).not_to have_button 'Subscribe'
        expect(page).to have_button 'Unsubscribe'

        click_button 'Unsubscribe'

        expect(page).to have_button 'Subscribe'
        expect(page).not_to have_button 'Unsubscribe'
      end
    end
  end

  context 'when not signed in' do
    it 'users can not subscribe/unsubscribe to labels' do
      visit group_labels_path(group)

      expect(page).to have_content 'feature'
      expect(page).not_to have_button('Subscribe')
    end
  end

  def click_link_on_dropdown(text)
    find('.dropdown-group-label').click

    page.within('.dropdown-group-label') do
      find('a.js-subscribe-button', text: text).click
    end
  end
end
