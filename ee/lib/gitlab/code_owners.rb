# frozen_string_literal: true

module Gitlab
  module CodeOwners
    FILE_NAME = 'CODEOWNERS'
    FILE_PATHS = [FILE_NAME, "docs/#{FILE_NAME}", ".gitlab/#{FILE_NAME}"].freeze

    def self.for_blob(blob)
      if blob.project.feature_available?(:code_owners)
        Loader.new(blob.project, blob.commit_id, blob.path).users
      else
        User.none # rubocop: disable CodeReuse/ActiveRecord
      end
    end
  end
end
