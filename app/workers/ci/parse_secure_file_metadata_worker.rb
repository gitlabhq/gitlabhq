# frozen_string_literal: true

module Ci
  class ParseSecureFileMetadataWorker
    include ::ApplicationWorker

    feature_category :mobile_devops
    urgency :low
    idempotent!

    def perform(secure_file_id)
      ::Ci::SecureFile.find_by_id(secure_file_id).try(&:update_metadata!)
    end
  end
end
