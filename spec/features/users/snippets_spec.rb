require 'spec_helper'

describe 'Snippets tab on a user profile', feature: true, js: true do
  include WaitForAjax

  context 'when the user has snippets' do
    let(:user) { create(:user) }
    let!(:snippets) { create_list(:snippet, 2, :public, author: user) }
    before do
      allow(Snippet).to receive(:default_per_page).and_return(1)
      visit user_path(user)
      page.within('.user-profile-nav') { click_link 'Snippets' }
      wait_for_ajax
    end

    it_behaves_like 'paginated snippets', remote: true
  end
end
