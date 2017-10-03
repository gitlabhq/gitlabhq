module SystemCheck
  module App
    class InitScriptUpToDateCheck < SystemCheck::BaseCheck
      SCRIPT_PATH = '/etc/init.d/gitlab'.freeze

      set_name 'Init script up-to-date?'
      set_skip_reason 'skipped (omnibus-gitlab has no init script)'

      def skip?
        return true if omnibus_gitlab?

        unless init_file_exists?
          self.skip_reason = "can't check because of previous errors"

          true
        end
      end

      def check?
        recipe_path = Rails.root.join('lib/support/init.d/', 'gitlab')

        recipe_content = File.read(recipe_path)
        script_content = File.read(SCRIPT_PATH)

        recipe_content == script_content
      end

      def show_error
        try_fixing_it(
          'Re-download the init script'
        )
        for_more_information(
          see_installation_guide_section 'Install Init Script'
        )
        fix_and_rerun
      end

      private

      def init_file_exists?
        File.exist?(SCRIPT_PATH)
      end
    end
  end
end
