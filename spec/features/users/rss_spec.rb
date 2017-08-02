require 'spec_helper'

feature 'User RSS' do
  let(:user) { create(:user) }
  let(:path) { user_path(create(:user)) }

  context 'when signed in' do
    before do
      sign_in(user)
      visit path
    end

    it_behaves_like "it has an RSS button with current_user's RSS token"
  end

  context 'when signed out' do
    before do
      visit path
    end

    it_behaves_like "it has an RSS button without an RSS token"
  end
end
