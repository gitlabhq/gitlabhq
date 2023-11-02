# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User visits the authentication log', feature_category: :user_profile do
  let(:user) { create(:user) }

  context 'when user has activity' do
    before do
      create(:closed_issue_event, author: user)
      gitlab_sign_in(user)
    end

    it 'shows user activity' do
      visit(audit_log_profile_path)

      expect(page).to have_content 'Signed in with standard authentication'
    end
  end
end
