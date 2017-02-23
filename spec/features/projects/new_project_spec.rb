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

  context "Namespace selector" do
    context "with user namespace" do
      before do
        visit new_project_path
      end

      it "selects the user namespace" do
        namespace = find("#project_namespace_id")

        expect(namespace.text).to eq user.username
      end
    end

    context "with group namespace" do
      let(:group) { create(:group, :private, owner: user) }

      before do
        group.add_owner(user)
        visit new_project_path(namespace_id: group.id)
      end

      it "selects the group namespace" do
        namespace = find("#project_namespace_id option[selected]")

        expect(namespace.text).to eq group.name
      end

      context "on validation error" do
        before do
          fill_in('project_path', with: 'private-group-project')
          choose('Internal')
          click_button('Create project')

          expect(page).to have_css '.project-edit-errors .alert.alert-danger'
        end

        it "selects the group namespace" do
          namespace = find("#project_namespace_id option[selected]")

          expect(namespace.text).to eq group.name
        end
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
