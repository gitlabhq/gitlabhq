# frozen_string_literal: true

module SystemCheck
  module App
    class UploadsPathPermissionCheck < SystemCheck::BaseCheck
      set_name 'Uploads directory has correct permissions?'
      set_skip_reason 'skipped (no uploads folder found)'

      def skip?
        !File.directory?(rails_uploads_path)
      end

      def check?
        File.stat(uploads_fullpath).mode == 040700
      end

      def show_error
        try_fixing_it(
          "sudo chmod 700 #{uploads_fullpath}"
        )
        for_more_information(
          see_installation_guide_section('GitLab')
        )
        fix_and_rerun
      end

      private

      def rails_uploads_path
        Rails.root.join('public/uploads')
      end

      def uploads_fullpath
        File.realpath(rails_uploads_path)
      end
    end
  end
end
