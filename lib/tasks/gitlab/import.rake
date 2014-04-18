namespace :gitlab do
  namespace :import do
    # How to use:
    #
    #  1. copy the bare repos under the repos_path (commonly /home/git/repositories)
    #  2. run: bundle exec rake gitlab:import:repos RAILS_ENV=production
    #
    # Notes:
    #  * The project owner will set to the first administator of the system
    #  * Existing projects will be skipped
    #
    desc "GITLAB | Import bare repositories from gitlab_shell -> repos_path into GitLab project instance"
    task repos: :environment do

      git_base_path = Gitlab.config.gitlab_shell.repos_path
      repos_to_import = Dir.glob(git_base_path + '/**/*.git')

      namespaces = Namespace.pluck(:path)

      repos_to_import.each do |repo_path|
        # strip repo base path
        repo_path[0..git_base_path.length] = ''

        path = repo_path.sub(/\.git$/, '')
        name = File.basename path
        group_name = File.dirname path
        group_name = nil if group_name == '.'

        # Skip if group or user
        next if namespaces.include?(name)

        puts "Processing #{repo_path}".yellow

        if path =~ /.wiki\Z/
          puts " * Skipping wiki repo"
          next
        end

        project = Project.find_with_namespace(path)

        if project
          puts " * #{project.name} (#{repo_path}) exists"
        else
          user = User.admins.first

          project_params = {
            name: name,
            path: name
          }

          # find group namespace
          if group_name
            group = Group.find_by(path: group_name)
            # create group namespace
            if !group
              group = Group.new(:name => group_name)
              group.path = group_name
              group.owner = user
              if group.save
                puts " * Created Group #{group.name} (#{group.id})".green
              else
                puts " * Failed trying to create group #{group.name}".red
              end
            end
            # set project group
            project_params[:namespace_id] = group.id
          end

          project = Projects::CreateService.new(user, project_params).execute

          if project.valid?
            puts " * Created #{project.name} (#{repo_path})".green
          else
            puts " * Failed trying to create #{project.name} (#{repo_path})".red
          end
        end
      end

      puts "Done!".green
    end
  end
end
