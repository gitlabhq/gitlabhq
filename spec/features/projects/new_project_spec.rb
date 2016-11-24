require "spec_helper"

feature "New project", feature: true do
  context "Visibility level selector" do
    let(:user) { create(:admin) }

    before { login_as(user) }

    Gitlab::VisibilityLevel.options.each do |key, level|
      it "sets selector to #{key}" do
        stub_application_setting(default_project_visibility: level)

        visit new_project_path

        expect(find_field("project_visibility_level_#{level}")).to be_checked
      end
    end
  end
end
