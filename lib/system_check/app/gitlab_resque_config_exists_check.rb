# frozen_string_literal: true

module SystemCheck
  module App
    class GitlabResqueConfigExistsCheck < SystemCheck::BaseCheck
      set_name 'Resque config exists?'

      def check?
        resque_config_file = Rails.root.join('config/resque.yml')

        File.exist?(resque_config_file)
      end

      def show_error
        try_fixing_it(
          'Copy config/resque.yml.example to config/resque.yml',
          'Update config/resque.yml to match your setup'
        )
        for_more_information(
          see_installation_guide_section('GitLab')
        )
        fix_and_rerun
      end
    end
  end
end
