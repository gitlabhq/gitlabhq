# frozen_string_literal: true

module SystemCheck
  module App
    class TmpWritableCheck < SystemCheck::BaseCheck
      set_name 'Tmp directory writable?'

      def check?
        File.writable?(tmp_path)
      end

      def show_error
        try_fixing_it(
          "sudo chown -R gitlab #{tmp_path}",
          "sudo chmod -R u+rwX #{tmp_path}"
        )
        for_more_information(
          see_installation_guide_section('GitLab')
        )
        fix_and_rerun
      end

      private

      def tmp_path
        Rails.root.join('tmp')
      end
    end
  end
end
