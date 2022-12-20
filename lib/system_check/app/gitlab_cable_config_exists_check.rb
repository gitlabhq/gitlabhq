# frozen_string_literal: true

module SystemCheck
  module App
    class GitlabCableConfigExistsCheck < SystemCheck::BaseCheck
      set_name 'Cable config exists?'

      def check?
        cable_config_file = Rails.root.join('config/cable.yml')

        File.exist?(cable_config_file)
      end

      def show_error
        try_fixing_it(
          'Copy config/cable.yml.example to config/cable.yml',
          'Update config/cable.yml to match your setup'
        )
        for_more_information(
          see_installation_guide_section('GitLab')
        )
        fix_and_rerun
      end
    end
  end
end
