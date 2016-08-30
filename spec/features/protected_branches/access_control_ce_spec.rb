RSpec.shared_examples "protected branches > access control > CE" do
  ProtectedBranch::PushAccessLevel.human_access_levels.each do |(access_type_id, access_type_name)|
    it "allows creating protected branches that #{access_type_name} can push to" do
      visit namespace_project_protected_branches_path(project.namespace, project)
      set_protected_branch_name('master')
      within('.new_protected_branch') do
        allowed_to_push_button = find(".js-allowed-to-push")

        unless allowed_to_push_button.text == access_type_name
          allowed_to_push_button.click
          within(".dropdown.open .dropdown-menu") { click_on access_type_name }
        end
      end
      click_on "Protect"

      expect(ProtectedBranch.count).to eq(1)
      expect(ProtectedBranch.last.push_access_levels.map(&:access_level)).to eq([access_type_id])
    end

    it "allows updating protected branches so that #{access_type_name} can push to them" do
      visit namespace_project_protected_branches_path(project.namespace, project)
      set_protected_branch_name('master')
      click_on "Protect"

      expect(ProtectedBranch.count).to eq(1)

      within(".protected-branches-list") do
        find(".js-allowed-to-push").click
        within('.js-allowed-to-push-container') { click_on access_type_name }
      end

      wait_for_ajax
      expect(ProtectedBranch.last.push_access_levels.map(&:access_level)).to include(access_type_id)
    end
  end

  ProtectedBranch::MergeAccessLevel.human_access_levels.each do |(access_type_id, access_type_name)|
    it "allows creating protected branches that #{access_type_name} can merge to" do
      visit namespace_project_protected_branches_path(project.namespace, project)
      set_protected_branch_name('master')
      within('.new_protected_branch') do
        allowed_to_merge_button = find(".js-allowed-to-merge")

        unless allowed_to_merge_button.text == access_type_name
          allowed_to_merge_button.click
          within(".dropdown.open .dropdown-menu") { click_on access_type_name }
        end
      end
      click_on "Protect"

      expect(ProtectedBranch.count).to eq(1)
      expect(ProtectedBranch.last.merge_access_levels.map(&:access_level)).to eq([access_type_id])
    end

    it "allows updating protected branches so that #{access_type_name} can merge to them" do
      visit namespace_project_protected_branches_path(project.namespace, project)
      set_protected_branch_name('master')
      click_on "Protect"

      expect(ProtectedBranch.count).to eq(1)

      within(".protected-branches-list") do
        find(".js-allowed-to-merge").click
        within('.js-allowed-to-merge-container') { click_on access_type_name }
      end

      wait_for_ajax
      expect(ProtectedBranch.last.merge_access_levels.map(&:access_level)).to include(access_type_id)
    end
  end
end
