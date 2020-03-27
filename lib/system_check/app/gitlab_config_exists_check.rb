# frozen_string_literal: true

module SystemCheck
  module App
    class GitlabConfigExistsCheck < SystemCheck::BaseCheck
      set_name 'GitLab config exists?'

      def check?
        gitlab_config_file = Rails.root.join('config', 'gitlab.yml')

        File.exist?(gitlab_config_file)
      end

      def show_error
        try_fixing_it(
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
