# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User RSS', feature_category: :user_profile do
  let(:user) { create(:user) }
  let(:path) { user_path(create(:user)) }

  before do
    stub_feature_flags(user_profile_overflow_menu_vue: false)
  end

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

  # TODO: implement tests before the FF "user_profile_overflow_menu_vue" is turned on
  # See: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122971
  # Related Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/416974
end
