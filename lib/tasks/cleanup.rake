# frozen_string_literal: true

namespace :gitlab do
  namespace :cleanup do
    desc "GitLab | Cleanup | Delete moved repositories"
    task moved: :gitlab_environment do
      warn_user_is_not_gitlab
      remove_flag = ENV['REMOVE']

      Gitlab.config.repositories.storages.each do |name, repository_storage|
        repo_root = repository_storage.legacy_disk_path.chomp('/')
        # Look for global repos (legacy, depth 1) and normal repos (depth 2)
        IO.popen(%W(find #{repo_root} -mindepth 1 -maxdepth 2 -name *+moved*.git)) do |find|
          find.each_line do |path|
            path.chomp!

            if remove_flag
              if FileUtils.rm_rf(path)
                puts "Removed...#{path}".color(:green)
              else
                puts "Cannot remove #{path}".color(:red)
              end
            else
              puts "Can be removed: #{path}".color(:green)
            end
          end
        end
      end

      unless remove_flag
        puts "To cleanup these repositories run this command with REMOVE=true".color(:yellow)
      end
    end
  end
end
