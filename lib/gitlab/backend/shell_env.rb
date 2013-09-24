module Gitlab
  # This module provide 2 methods
  # to set specific ENV variables for GitLab Shell
  module ShellEnv
    extend self

    def set_env(user)
      # Set GL_ID env variable
      ENV['GL_ID'] = "user-#{user.id}"
    end

    def reset_env
      # Reset GL_ID env variable
      ENV['GL_ID'] = nil
    end
  end
end
