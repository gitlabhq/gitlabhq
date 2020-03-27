# frozen_string_literal: true

module SystemCheck
  module App
    class UploadsDirectoryExistsCheck < SystemCheck::BaseCheck
      set_name 'Uploads directory exists?'

      def check?
        File.directory?(Rails.root.join('public/uploads'))
      end

      def show_error
        try_fixing_it(
          "sudo -u #{gitlab_user} mkdir #{Rails.root}/public/uploads"
        )
        for_more_information(
          see_installation_guide_section('GitLab')
        )
        fix_and_rerun
      end
    end
  end
end
