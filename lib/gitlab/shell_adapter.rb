# frozen_string_literal: true

# == GitLab Shell mixin
#
# Provide a shortcut to Gitlab::Shell instance by gitlab_shell
#
module Gitlab
  module ShellAdapter
    def gitlab_shell
      @gitlab_shell ||= Gitlab::Shell.new
    end
  end
end
