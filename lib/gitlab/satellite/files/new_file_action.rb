require_relative 'file_action'

module Gitlab
  module Satellite
    class NewFileAction < FileAction
      # Updates the files content and creates a new commit for it
      #
      # Returns false if the ref has been updated while editing the file
      # Returns false if committing the change fails
      # Returns false if pushing from the satellite to bare repo failed or was rejected
      # Returns true otherwise
      def commit!(content, commit_message, encoding)
        in_locked_and_timed_satellite do |repo|
          prepare_satellite!(repo)

          # create target branch in satellite at the corresponding commit from bare repo
          repo.git.checkout({raise: true, timeout: true, b: true}, ref, "origin/#{ref}")

          file_path_in_satellite = File.join(repo.working_dir, file_path)
          dir_name_in_satellite = File.dirname(file_path_in_satellite)

          # Prevent relative links
          unless safe_path?(file_path_in_satellite)
            Gitlab::GitLogger.error("FileAction: Relative path not allowed")
            return false
          end

          # Create dir if not exists
          FileUtils.mkdir_p(dir_name_in_satellite)

          # Write file
          write_file(file_path_in_satellite, content, encoding)

          # add new file
          repo.add(file_path_in_satellite)

          # commit the changes
          # will raise CommandFailed when commit fails
          repo.git.commit(raise: true, timeout: true, a: true, m: commit_message)


          # push commit back to bare repo
          # will raise CommandFailed when push fails
          repo.git.push({raise: true, timeout: true}, :origin, ref)

          # everything worked
          true
        end
      rescue Grit::Git::CommandFailed => ex
        Gitlab::GitLogger.error(ex.message)
        false
      end
    end
  end
end
