require "spec_helper"

describe "Admin interacts with push rules" do
  set(:user) { create(:admin) }

  before do
    sign_in(user)
  end

  push_rules_with_titles = {
    reject_unsigned_commits: "Reject unsigned commits",
    commit_committer_check: "Committer restriction"
  }

  push_rules_with_titles.each do |rule_attr, title|
    context "when #{rule_attr} is unlicensed" do
      before do
        stub_licensed_features(rule_attr => false)

        visit(admin_push_rule_path)
      end

      it { expect(page).not_to have_content(title) }
    end

    context "when #{rule_attr} is licensed" do
      before do
        stub_licensed_features(rule_attr => true)

        visit(admin_push_rule_path)
      end

      it { expect(page).to have_content(title) }
    end
  end

  context "when creating push rule" do
    before do
      visit(admin_push_rule_path)
    end

    it "creates new rule" do
      fill_in("Commit message", with: "my_string")
      click_button("Save Push Rules")

      expect(page).to have_selector("input[value='my_string']")
    end
  end
end
