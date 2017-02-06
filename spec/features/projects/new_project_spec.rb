require "spec_helper"

feature "New project", feature: true do
  let(:user) { create(:admin) }

  before do
    login_as(user)
  end

  context "Visibility level selector" do
    Gitlab::VisibilityLevel.options.each do |key, level|
      it "sets selector to #{key}" do
        stub_application_setting(default_project_visibility: level)

        visit new_project_path

        expect(find_field("project_visibility_level_#{level}")).to be_checked
      end
    end
  end

  context 'Import project options' do
    before do
      visit new_project_path
    end

    it 'does not autocomplete sensitive git repo URL' do
      autocomplete = find('#project_import_url')['autocomplete']

      expect(autocomplete).to eq('off')
    end
  end
end
