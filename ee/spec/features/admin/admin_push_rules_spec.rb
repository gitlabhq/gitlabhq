require 'spec_helper'

describe "Admin::PushRules"  do
  let(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
  end

  push_rules_with_titles = {
    reject_unsigned_commits: 'Reject unsigned commits',
    commit_committer_check: 'Committer restriction'
  }

  push_rules_with_titles.each do |rule_attr, title|
    context "when #{rule_attr} is unlicensed" do
      before do
        stub_licensed_features(rule_attr => false)
      end

      it 'does not render the setting checkbox' do
        visit admin_push_rule_path

        expect(page).not_to have_content(title)
      end
    end

    context "when #{rule_attr} is licensed" do
      before do
        stub_licensed_features(rule_attr => true)
      end

      it 'renders the setting checkbox' do
        visit admin_push_rule_path

        expect(page).to have_content(title)
      end
    end
  end
end
