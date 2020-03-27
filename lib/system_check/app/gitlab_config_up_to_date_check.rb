# frozen_string_literal: true

module SystemCheck
  module App
    class GitlabConfigUpToDateCheck < SystemCheck::BaseCheck
      set_name 'GitLab config up to date?'
      set_skip_reason "can't check because of previous errors"

      def skip?
        gitlab_config_file = Rails.root.join('config', 'gitlab.yml')
        !File.exist?(gitlab_config_file)
      end

      def check?
        # omniauth or ldap could have been deleted from the file
        !Gitlab.config['git_host']
      end

      def show_error
        try_fixing_it(
          'Back-up your config/gitlab.yml',
          'Copy config/gitlab.yml.example to config/gitlab.yml',
          'Update config/gitlab.yml to match your setup'
        )
        for_more_information(
          see_installation_guide_section('GitLab')
        )
        fix_and_rerun
      end
    end
  end
end
