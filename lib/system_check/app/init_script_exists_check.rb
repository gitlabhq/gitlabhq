# frozen_string_literal: true

module SystemCheck
  module App
    class InitScriptExistsCheck < SystemCheck::BaseCheck
      set_name 'Init script exists?'
      set_skip_reason 'skipped (omnibus-gitlab has no init script)'

      def skip?
        omnibus_gitlab?
      end

      def check?
        script_path = '/etc/init.d/gitlab'
        File.exist?(script_path)
      end

      def show_error
        try_fixing_it(
          'Install the init script'
        )
        for_more_information(
          see_installation_guide_section('Install Init Script')
        )
        fix_and_rerun
      end
    end
  end
end
