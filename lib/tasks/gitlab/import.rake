namespace :gitlab do
  namespace :import do
    # How to use:
    #
    #  1. copy your bare repos under git base_path
    #  2. run bundle exec rake gitlab:import:repos RAILS_ENV=production
    #
    # Notes:
    #  * project owner will be a first admin
    #  * existing projects will be skipped
    #
    desc "GITLAB | Import bare repositories from git_host -> base_path into GitLab project instance"
    task repos: :environment do

      git_base_path = Gitlab.config.gitlab_shell.repos_path
      repos_to_import = Dir.glob(git_base_path + '/**/*.git')

      namespaces = Namespace.pluck(:path)

      repos_to_import.each do |repo_path|
        # strip repo base path
        repo_path[0..git_base_path.length] = ''

        path = repo_path.sub(/\.git$/, '')
        name = File.basename path
        folder_name = File.dirname path
        folder_name = nil if folder_name == '.'

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

          if !folder_name
            old_path = File.join(git_base_path,repo_path)
            cur_space = Namespace.find_by_owner_id(user.id)
            folder_name = cur_space.path
            new_folder = File.join(git_base_path, folder_name)
            new_path = File.join(new_folder,repo_path)
            FileUtils.mv(old_path, new_path)
          end

          # find the namespace
          if folder_name
            result_id = nil
            cur_space = Namespace.find_by_path(folder_name)
            # if the namespace does not exist
            if !cur_space
              # create group namespace
              group = Group.new(:name => folder_name)
              group.path = folder_name
              group.owner = user
              if group.save
                puts " * Created Group #{group.name} (#{group.id})".green
                result_id = group.id
              else
                puts " * Failed trying to create group #{group.name}".red
              end
            else
              # namespace exists no need to create
              user = User.find_by_id(cur_space.owner_id)
              result_id = cur_space.id
            end
            
            # set project group/user
            project_params[:namespace_id] = result_id

            project = Projects::CreateContext.new(user, project_params).execute

            if project.valid?
              puts " * Created #{project.name} (#{repo_path})".green
            else
              puts " * Failed trying to create #{project.name} (#{repo_path})".red
            end
          else
            puts " * The folder move failed or the folder was misnamed".red
          end
        end
      end
      puts "Done!".green
    end
  end
end
