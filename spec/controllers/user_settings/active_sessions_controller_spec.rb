# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserSettings::ActiveSessionsController, feature_category: :user_profile do
  describe 'DELETE destroy' do
    let_it_be(:user) { create(:user) }

    before do
      sign_in(user)
    end

    it 'invalidates all remember user tokens' do
      ActiveSession.set(user, request)
      session_id = request.session.id.private_id
      user.remember_me!

      delete :destroy, params: { id: session_id }

      expect(user.reload.remember_created_at).to be_nil
    end
  end
end
