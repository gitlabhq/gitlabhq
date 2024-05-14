# frozen_string_literal: true

namespace :gitlab do
  namespace :web_hook do
    desc "GitLab | Webhook | Adds a webhook to the projects"
    task add: :environment do
      web_hook_url = ENV['URL']
      namespace_path = ENV['NAMESPACE']

      projects = find_projects(namespace_path)

      puts "Adding webhook '#{web_hook_url}' to:"
      projects.find_each(batch_size: 1000) do |project|
        print "- #{project.name} ... "
        web_hook = project.hooks.new(url: web_hook_url)
        if web_hook.save
          puts Rainbow("added").green
        else
          print Rainbow("failed").red
          puts "  [#{web_hook.errors.full_messages.to_sentence}]"
        end
      end
    end

    desc "GitLab | Webhook | Remove a webhook from a namespace"
    task rm: :environment do |task|
      web_hook_url = ENV['URL']
      namespace_path = ENV['NAMESPACE']

      raise ArgumentError, 'URL is required' unless web_hook_url

      web_hooks = find_web_hooks(namespace_path)

      puts "Removing webhooks with the url '#{web_hook_url}' ... "

      # FIXME: Hook URLs are now encrypted, so there is no way to efficiently
      # find them all in SQL. For now, check them in Ruby. If this is too slow,
      # we could consider storing a hash of the URL alongside the encrypted
      # value to speed up searches
      count = 0
      service = WebHooks::AdminDestroyService.new(rake_task: task)

      web_hooks.find_each do |hook|
        next unless hook.url == web_hook_url

        result = service.execute(hook)

        raise "Unable to destroy Web hook" unless result[:status] == :success

        count += 1
      end

      puts "#{count} webhooks were removed."
    end

    desc "GitLab | Webhook | List webhooks"
    task list: :environment do
      namespace_path = ENV['NAMESPACE']

      web_hooks = find_web_hooks(namespace_path)
      web_hooks.find_each do |hook|
        puts "#{hook.project.name.truncate(20).ljust(20)} -> #{hook.url}"
      end

      puts "\n#{web_hooks.count} webhooks found."
    end
  end

  def find_projects(namespace_path)
    if namespace_path.blank?
      Project
    else
      namespace = Namespace.find_by_full_path(namespace_path)

      unless namespace
        puts Rainbow("Namespace not found: #{namespace_path}").red
        exit 2
      end

      Project.in_namespace(namespace.id)
    end
  end

  def find_web_hooks(namespace_path)
    if namespace_path.blank?
      ProjectHook
    else
      project_ids = find_projects(namespace_path).select(:id)

      ProjectHook.where(project_id: project_ids)
    end
  end
end
