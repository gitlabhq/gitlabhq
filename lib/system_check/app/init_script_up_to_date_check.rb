module SystemCheck
  module App
    class InitScriptUpToDateCheck < SystemCheck::BaseCheck
      SCRIPT_PATH = '/etc/init.d/gitlab'.freeze

      set_name 'Init script up-to-date?'
      set_skip_reason 'skipped (omnibus-gitlab has no init script)'

      def skip?
        omnibus_gitlab?
      end

      def multi_check
        recipe_path = Rails.root.join('lib/support/init.d/', 'gitlab')

        unless File.exist?(SCRIPT_PATH)
          $stdout.puts "can't check because of previous errors".color(:magenta)
          return
        end

        recipe_content = File.read(recipe_path)
        script_content = File.read(SCRIPT_PATH)

        if recipe_content == script_content
          $stdout.puts 'yes'.color(:green)
        else
          $stdout.puts 'no'.color(:red)
          show_error
        end
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
    end
  end
end
