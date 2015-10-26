namespace :gitlab do
  namespace :web_hook do
    desc "GitLab | Adds a web hook to the projects"
    task :add => :environment do
      web_hook_url = ENV['URL']
      namespace_path = ENV['NAMESPACE']

      projects = find_projects(namespace_path)

      with_hook_scope = ProjectHook.where(url: web_hook_url)
      with_hook_scope = with_hook_scope.where(project: projects) unless projects == Project # there is Rails bug
      projects_ids_with_hook = with_hook_scope.pluck(:project_id)

      puts "Adding web hook '#{web_hook_url}' to:"
      projects.find_each(batch_size: 1000) do |project|
        print "- #{project.name} ... "
        if projects_ids_with_hook.include?(project.id)
          puts "skipped".yellow
        else
          web_hook = project.hooks.new(url: web_hook_url)
          if web_hook.save
            puts "added".green
          else
            print "failed".red
            puts "  [#{web_hook.errors.full_messages.to_sentence}]"
          end
        end
      end
    end

    desc "GitLab | Remove a web hook from the projects"
    task :rm => :environment do
      web_hook_url = ENV['URL']
      namespace_path = ENV['NAMESPACE']

      projects = find_projects(namespace_path)
      projects_ids = projects.pluck(:id)

      puts "Removing web hooks with the url '#{web_hook_url}' ... "
      count = WebHook.where(url: web_hook_url, project_id: projects_ids, type: 'ProjectHook').delete_all
      puts "#{count} web hooks were removed."
    end

    desc "GitLab | List web hooks"
    task :list => :environment do
      namespace_path = ENV['NAMESPACE']

      projects = find_projects(namespace_path)
      web_hooks = projects.all.map(&:hooks).flatten
      web_hooks.each do |hook|
        puts "#{hook.project.name.truncate(20).ljust(20)} -> #{hook.url}"
      end

      puts "\n#{web_hooks.size} web hooks found."
    end
  end

  def find_projects(namespace_path)
    if namespace_path.blank?
      Project
    elsif namespace_path == '/'
      Project.in_namespace(nil)
    else
      namespace = Namespace.where(path: namespace_path).first
      if namespace
        Project.in_namespace(namespace.id)
      else
        puts "Namespace not found: #{namespace_path}".red
        exit 2
      end
    end
  end
end
