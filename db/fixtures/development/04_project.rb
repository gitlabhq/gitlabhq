Gitlab::Seeder.quiet do
  project_urls = [
    'https://github.com/documentcloud/underscore.git',
    'https://github.com/diaspora/diaspora.git',
    'https://github.com/diaspora/diaspora-project-site.git',
    'https://github.com/diaspora/diaspora-client.git',
    'https://github.com/brightbox/brightbox-cli.git',
    'https://github.com/brightbox/puppet.git',
    'https://github.com/gitlabhq/gitlabhq.git',
    'https://github.com/gitlabhq/gitlab-ci.git',
    'https://github.com/gitlabhq/gitlab-recipes.git',
    'https://github.com/gitlabhq/gitlab-shell.git',
    'https://github.com/gitlabhq/grack.git',
    'https://github.com/gitlabhq/testme.git',
    'https://github.com/twitter/flight.git',
    'https://github.com/twitter/typeahead.js.git',
    'https://github.com/h5bp/html5-boilerplate.git',
    'https://github.com/h5bp/mobile-boilerplate.git',
  ]

  def check_project(project)
    if project.valid?
      print '.'
    else
      puts project.errors.full_messages
      print 'F'
    end
  end

  project_urls.each_with_index do |url, i|
    group_path, project_path = url.split('/')[-2..-1]
    group = Group.find_by(path: group_path)
    unless group
      group = Group.new(
        name: group_path.titleize,
        path: group_path
      )
      group.description = Faker::Lorem.sentence
      group.save
      group.add_owner(User.first)
    end
    project_path.gsub!(".git", "")
    params = {
      import_url: url,
      namespace_id: group.id,
      name: project_path.titleize,
      description: Faker::Lorem.sentence
    }
    project = Projects::CreateService.new(User.first, params).execute
    check_project(project)
  end

  if Settings.gitlab.include_predictable_data
    visibility_level_name_values = Gitlab::VisibilityLevel.options
    User.where('username LIKE ?', 'user%').
         order('CHAR_LENGTH(username), username').limit(5).each do |user|
      i = 1
      visibility_level_name_values.each do |name, value|
        params = {
          description: "Description #{name} #{i}",
          name: "Project Name #{name} #{i}",
          visibility_level: value,
        }
        project = Projects::CreateService.new(user, params).execute
        check_project(project)
      end
      i += 1
    end
  end
end
