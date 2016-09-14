RSpec.shared_examples "protected branches > access control > EE" do
  [['merge', ProtectedBranch::MergeAccessLevel], ['push', ProtectedBranch::PushAccessLevel]].each do |git_operation, access_level_class|
    # Need to set a default for the `git_operation` access level that _isn't_ being tested
    other_git_operation = git_operation == 'merge' ? 'push' : 'merge'

    it "allows creating protected branches that roles and users can #{git_operation} to" do
      users = create_list(:user, 5)
      users.each { |user| project.team << [user, :developer] }
      roles = access_level_class.human_access_levels

      visit namespace_project_protected_branches_path(project.namespace, project)

      set_protected_branch_name('master')
      set_allowed_to(git_operation, users.map(&:name))
      set_allowed_to(git_operation, roles.values)
      set_allowed_to(other_git_operation)

      click_on "Protect"

      within(".protected-branches-list") { expect(page).to have_content('master') }
      expect(ProtectedBranch.count).to eq(1)
      roles.each { |(access_type_id, _)| expect(ProtectedBranch.last.send("#{git_operation}_access_levels".to_sym).map(&:access_level)).to include(access_type_id) }
      users.each { |user| expect(ProtectedBranch.last.send("#{git_operation}_access_levels".to_sym).map(&:user_id)).to include(user.id) }
    end

    it "allows updating protected branches that roles and users can #{git_operation} to" do
      users = create_list(:user, 5)
      users.each { |user| project.team << [user, :developer] }
      roles = access_level_class.human_access_levels

      visit namespace_project_protected_branches_path(project.namespace, project)
      set_protected_branch_name('master')
      set_allowed_to('merge')
      set_allowed_to('push')

      click_on "Protect"

      within(".js-protected-branch-edit-form") do
        set_allowed_to(git_operation, users.map(&:name))
        set_allowed_to(git_operation, roles.values)
      end

      wait_for_ajax

      expect(ProtectedBranch.count).to eq(1)
      roles.each { |(access_type_id, _)| expect(ProtectedBranch.last.send("#{git_operation}_access_levels".to_sym).map(&:access_level)).to include(access_type_id) }
      users.each { |user| expect(ProtectedBranch.last.send("#{git_operation}_access_levels".to_sym).map(&:user_id)).to include(user.id) }
    end

    it "prepends selected users that can #{git_operation} to" do
      users = create_list(:user, 21)
      users.each { |user| project.team << [user, :developer] }
      roles = access_level_class.human_access_levels

      visit namespace_project_protected_branches_path(project.namespace, project)

      # Create Protected Branch
      set_protected_branch_name('master')
      set_allowed_to(git_operation, roles.values)
      set_allowed_to(other_git_operation)

      click_on 'Protect'

      # Update Protected Branch
      within(".protected-branches-list") do
        find(".js-allowed-to-#{git_operation}").click
        find(".dropdown-input-field").set(users.last.name) # Find a user that is not loaded
        wait_for_ajax
        click_on users.last.name
        find(".js-allowed-to-#{git_operation}").click # close
      end
      
      wait_for_ajax

      # Verify the user is appended in the dropdown
      find(".protected-branches-list .js-allowed-to-#{git_operation}").click
      expect(page).to have_selector '.dropdown-content .is-active', text: users.last.name

      expect(ProtectedBranch.count).to eq(1)
      roles.each { |(access_type_id, _)| expect(ProtectedBranch.last.send("#{git_operation}_access_levels".to_sym).map(&:access_level)).to include(access_type_id) }
      expect(ProtectedBranch.last.send("#{git_operation}_access_levels".to_sym).map(&:user_id)).to include(users.last.id)
    end
  end
end
