# frozen_string_literal: true

module Repositories
  class CommitsUploader < GitlabUploader
    include ObjectStorage::Concern

    DEFAULT_MAX_REQUEST_SIZE = 300.megabytes
    MAX_RATE_LIMITED_REQUEST_SIZE = 20.megabytes

    # On Cloud Native GitLab, /srv/gitlab/public/uploads/tmp is a shared mount.
    # Use a subpath from that directory to ensure the gitlab-workhorse and webservice
    # containers can both access this directory.
    def self.workhorse_local_upload_path
      Rails.root.join('public/uploads/tmp/commits').to_s
    end

    def self.direct_upload_enabled?
      false
    end

    def self.workhorse_authorize(has_length: true, maximum_size: max_request_size, **kwargs)
      super
    end

    def self.max_request_size
      ENV.fetch('GITLAB_COMMITS_MAX_REQUEST_SIZE_BYTES', DEFAULT_MAX_REQUEST_SIZE).to_i
    end
  end
end
