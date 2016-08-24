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
  end
end
