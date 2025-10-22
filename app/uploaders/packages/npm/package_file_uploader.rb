# frozen_string_literal: true

module Packages
  module Npm
    class PackageFileUploader < ::Packages::PackageFileUploader
      # On Cloud Native GitLab, /srv/gitlab/public/uploads/tmp is a shared mount.
      # Use a subpath from that directory to ensure the gitlab-workhorse and webservice
      # containers can both access this directory.
      def self.workhorse_local_upload_path
        Rails.root.join('public/uploads/tmp/npm_package_files').to_s
      end

      def self.direct_upload_enabled?
        false
      end
    end
  end
end
