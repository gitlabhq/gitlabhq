require 'spec_helper'

describe 'Snippets tab on a user profile', feature: true, js: true do
  include WaitForAjax

  let(:user) { create(:user) }

  context 'when the user has snippets' do
    before do
      create_list(:snippet, 25, :public, author: user)

      visit user_path(user)
      page.within('.user-profile-nav') { click_link 'Snippets' }
      wait_for_ajax
    end

    it 'is limited to 20 items per page' do
      expect(page.all('.snippets-list-holder .snippet-row').count).to eq(20)
    end

    context 'clicking on the link to the second page' do
      before { click_link('2') }

      it 'shows the remaining snippets' do
        expect(page.all('.snippets-list-holder .snippet-row').count).to eq(5)
      end
    end
  end
end
