require Rails.root.join('db', 'fixtures', Rails.env, 'fixtures_development_helper')

Gitlab::Seeder.quiet do
  Gitlab::VisibilityLevel.options.each do |visibility_label, visibility_value|
    visibility_label_downcase = visibility_label.downcase
    begin
      user = User.seed(:username) do |s|
        username = "#{visibility_label_downcase}-owner"
        s.username = username
        s.name = "#{visibility_label} Owner"
        s.email = "#{username}@example.com"
        s.password = '12345678'
        s.confirmed_at = DateTime.now
      end[0]

      # import_url does not work for local paths,
      # so we just copy the template repository in.
      unless Project.find_with_namespace("#{user.namespace.id}/"\
                                         "#{visibility_label_downcase}")
        params = {
          name: "#{visibility_label} Project",
          description: "#{visibility_label} Project description",
          namespace_id: user.namespace.id,
          visibility_level: visibility_value,
        }
        project = Projects::CreateService.new(user, params).execute
        new_path = project.repository.path
        FileUtils.rm_rf(new_path)
        FileUtils.cp_r(FixturesDevelopmentHelper.template_project.repository.path,
                       new_path)
      end

      print '.'
    rescue ActiveRecord::RecordNotSaved
      print 'F'
    end
  end
end
