# frozen_string_literal: true

module SystemCheck
  module App
    class LogWritableCheck < SystemCheck::BaseCheck
      set_name 'Log directory writable?'

      def check?
        File.writable?(log_path)
      end

      def show_error
        try_fixing_it(
          "sudo chown -R gitlab #{log_path}",
          "sudo chmod -R u+rwX #{log_path}"
        )
        for_more_information(
          see_installation_guide_section('GitLab')
        )
        fix_and_rerun
      end

      private

      def log_path
        Rails.root.join('log')
      end
    end
  end
end
