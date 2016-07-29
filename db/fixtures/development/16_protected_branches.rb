Gitlab::Seeder.quiet do
  admin_user = User.find(1)

  Project.all.each do |project|
    params = {
      name: 'master'
    }

    ProtectedBranches::CreateService.new(project, admin_user, params).execute
    print '.'
  end
end
