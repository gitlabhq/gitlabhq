namespace :gitlab do
  namespace :import do
    # How to use:
    #
    #  1. copy the bare repos under the repository storage paths (commonly the default path is /home/git/repositories)
    #  2. run: bundle exec rake gitlab:import:repos RAILS_ENV=production
    #
    # Notes:
    #  * The project owner will set to the first administator of the system
    #  * Existing projects will be skipped
    #
    desc "GitLab | Import bare repositories from repositories -> storages into GitLab project instance"
    task repos: :environment do
      if Project.current_application_settings.hashed_storage_enabled
        puts 'Cannot import repositories when Hashed Storage is enabled'.color(:red)

        exit 1
      end

      Gitlab.config.repositories.storages.each_value do |repository_storage|
        git_base_path = repository_storage['path']
        repos_to_import = Dir.glob(git_base_path + '/**/*.git')

        repos_to_import.each do |repo_path|
          # strip repo base path
          repo_path[0..git_base_path.length] = ''

          path = repo_path.sub(/\.git$/, '')
          group_name, name = File.split(path)
          group_name = nil if group_name == '.'

          puts "Processing #{repo_path}".color(:yellow)

          if path.end_with?('.wiki')
            puts " * Skipping wiki repo"
            next
          end

          project = Project.find_by_full_path(path)

          if project
            puts " * #{project.name} (#{repo_path}) exists"
          else
            user = User.admins.reorder("id").first

            project_params = {
              name: name,
              path: name
            }

            # find group namespace
            if group_name
              group = Namespace.find_by(path: group_name)
              # create group namespace
              unless group
                group = Group.new(name: group_name)
                group.path = group_name
                group.owner = user
                if group.save
                  puts " * Created Group #{group.name} (#{group.id})".color(:green)
                else
                  puts " * Failed trying to create group #{group.name}".color(:red)
                end
              end
              # set project group
              project_params[:namespace_id] = group.id
            end

            project = Projects::CreateService.new(user, project_params).execute

            if project.persisted?
              puts " * Created #{project.name} (#{repo_path})".color(:green)
              ProjectCacheWorker.perform_async(project.id)
            else
              puts " * Failed trying to create #{project.name} (#{repo_path})".color(:red)
              puts "   Errors: #{project.errors.messages}".color(:red)
            end
          end
        end
      end

      puts "Done!".color(:green)
    end
  end
end
