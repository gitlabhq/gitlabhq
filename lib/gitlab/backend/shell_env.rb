module Gitlab
  # This module provide 2 methods
  # to set specific ENV variables for GitLab Shell
  module ShellEnv
    extend self

    def set_env(user)
      # Set GL_ID env variable
      if user
        ENV['GL_ID'] = gl_id(user)
      end
    end

    def reset_env
      # Reset GL_ID env variable
      ENV['GL_ID'] = nil
    end

    def gl_id(user)
      if user.present?
        "user-#{user.id}"
      else
        # This empty string is used in the render_grack_auth_ok method
        ""
      end
    end
  end
end
