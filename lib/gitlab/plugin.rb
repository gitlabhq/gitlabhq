module Gitlab
  module Plugin
    def self.files
      Dir.glob(Rails.root.join('plugins', '*_plugin.rb'))
    end

    def self.execute_all_async(data)
      files.each do |file|
        PluginWorker.perform_async(file, data)
      end
    end

    def self.execute(file, data)
      # TODO: Implement
      #
      # Reuse some code from gitlab-shell https://gitlab.com/gitlab-org/gitlab-shell/blob/master/lib/gitlab_custom_hook.rb#L40
      # Pass data as STDIN (or JSON encode?)
      #
      # 1. Return true if 0 exit code
      # 2. Return false if non-zero exit code
    end
  end
end
