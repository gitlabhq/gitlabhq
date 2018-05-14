module Backup
  module Helper
    def access_denied_error(path)
      message = <<~EOS

      ### NOTICE ###
      As part of restore, the task tried to move existing content from #{path}.
      However, it seems that directory contains files/folders that are not owned
      by the user #{Gitlab.config.gitlab.user}. To proceed, please move the files
      or folders inside #{path} to a secure location so that #{path} is empty and
      run restore task again.

      EOS
      raise message
    end

    def resource_busy_error(path)
      message = <<~EOS

      ### NOTICE ###
      As part of restore, the task tried to rename `#{path}` before restoring.
      This could not be completed, perhaps `#{path}` is a mountpoint?

      To complete the restore, please move the contents of `#{path}` to a
      different location and run the restore task again.

      EOS
      raise message
    end
  end
end
