require 'spec_helper'

describe "Admin::PushRules"  do
  let(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
  end

  context 'when reject_unsigned_commits is unlicensed' do
    before do
      stub_licensed_features(reject_unsigned_commits: false)
    end

    it 'does not render the setting checkbox' do
      visit admin_push_rule_path

      expect(page).not_to have_content('Reject unsigned commits')
    end
  end

  context 'when reject_unsigned_commits is licensed' do
    before do
      stub_licensed_features(reject_unsigned_commits: true)
    end

    it 'renders the setting checkbox' do
      visit admin_push_rule_path

      expect(page).to have_content('Reject unsigned commits')
    end
  end
end
