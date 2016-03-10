namespace :gitlab do
  namespace :web_hook do
    desc "GitLab | Adds a webhook to the projects"
    task :add => :environment do
      web_hook_url = ENV['URL']
      namespace_path = ENV['NAMESPACE']

      projects = find_projects(namespace_path)

      puts "Adding webhook '#{web_hook_url}' to:"
      projects.find_each(batch_size: 1000) do |project|
        print "- #{project.name} ... "
        web_hook = project.hooks.new(url: web_hook_url)
        if web_hook.save
          puts "added".green
        else
          print "failed".red
          puts "  [#{web_hook.errors.full_messages.to_sentence}]"
        end
      end
    end

    desc "GitLab | Remove a webhook from the projects"
    task :rm => :environment do
      web_hook_url = ENV['URL']
      namespace_path = ENV['NAMESPACE']

      projects = find_projects(namespace_path)
      projects_ids = projects.pluck(:id)

      puts "Removing webhooks with the url '#{web_hook_url}' ... "
      count = WebHook.where(url: web_hook_url, project_id: projects_ids, type: 'ProjectHook').delete_all
      puts "#{count} webhooks were removed."
    end

    desc "GitLab | List webhooks"
    task :list => :environment do
      namespace_path = ENV['NAMESPACE']

      projects = find_projects(namespace_path)
      web_hooks = projects.all.map(&:hooks).flatten
      web_hooks.each do |hook|
        puts "#{hook.project.name.truncate(20).ljust(20)} -> #{hook.url}"
      end

      puts "\n#{web_hooks.size} webhooks found."
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
