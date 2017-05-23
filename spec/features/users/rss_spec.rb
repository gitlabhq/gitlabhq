require 'spec_helper'

feature 'User RSS' do
  let(:path) { user_path(create(:user)) }

  context 'when signed in' do
    before do
      login_as(create(:user))
      visit path
    end

    it_behaves_like "it has an RSS button with current_user's rss token"
  end

  context 'when signed out' do
    before do
      visit path
    end

    it_behaves_like "it has an RSS button without an rss token"
  end
end
