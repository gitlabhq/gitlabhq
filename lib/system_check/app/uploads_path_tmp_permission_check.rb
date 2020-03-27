# frozen_string_literal: true

module SystemCheck
  module App
    class UploadsPathTmpPermissionCheck < SystemCheck::BaseCheck
      set_name 'Uploads directory tmp has correct permissions?'
      set_skip_reason 'skipped (no tmp uploads folder yet)'

      def skip?
        !File.directory?(uploads_fullpath) || !Dir.exist?(upload_path_tmp)
      end

      def check?
        # If tmp upload dir has incorrect permissions, assume others do as well
        # Verify drwx------ permissions
        File.stat(upload_path_tmp).mode == 040700 && File.owned?(upload_path_tmp)
      end

      def show_error
        try_fixing_it(
          "sudo chown -R #{gitlab_user} #{uploads_fullpath}",
          "sudo find #{uploads_fullpath} -type f -exec chmod 0644 {} \\;",
          "sudo find #{uploads_fullpath} -type d -not -path #{uploads_fullpath} -exec chmod 0700 {} \\;"
        )
        for_more_information(
          see_installation_guide_section('GitLab')
        )
        fix_and_rerun
      end

      private

      def upload_path_tmp
        File.join(uploads_fullpath, 'tmp')
      end

      def uploads_fullpath
        File.realpath(Rails.root.join('public/uploads'))
      end
    end
  end
end
