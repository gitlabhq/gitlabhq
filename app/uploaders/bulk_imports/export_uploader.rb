# frozen_string_literal: true

module BulkImports
  class ExportUploader < ImportExportUploader
    EXTENSION_ALLOWLIST = %w[ndjson.gz tar.gz gz].freeze

    def mounted_as
      return super if model

      upload && upload[:mount_point].to_sym
    end

    private

    def dynamic_segment
      return super if model

      # The corresponding export model may already have been removed, in which
      # case we need to reconstruct this info based on what we have stored in
      # the upload model.
      #
      # Currently, there should be no way for model_type or model_id to be nil,
      # as they are requirements for table partitioning. I've included them here
      # for future-proofing's sake.
      #
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/542228
      unless upload && upload[:model_type] && upload[:mount_point] && upload[:model_id]
        raise StandardError, "Missing required upload attributes for path reconstruction"
      end

      File.join(
        upload[:model_type].constantize.underscore,
        upload[:mount_point],
        upload[:model_id].to_s
      )
    end
  end
end
