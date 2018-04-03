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
  end
end
