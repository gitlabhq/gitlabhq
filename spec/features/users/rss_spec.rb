# frozen_string_literal: true

require 'spec_helper'

describe 'User RSS' do
  let(:user) { create(:user) }
  let(:path) { user_path(create(:user)) }

  context 'when signed in' do
    before do
      sign_in(user)
      visit path
    end

    it_behaves_like "it has an RSS button with current_user's feed token"
  end

  context 'when signed out' do
    before do
      visit path
    end

    it_behaves_like "it has an RSS button without a feed token"
  end
end
