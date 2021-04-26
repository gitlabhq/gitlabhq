# frozen_string_literal: true

module Gitlab
  module ImportExport
    class UploadsRestorer < UploadsSaver
      def restore
        Gitlab::ImportExport::UploadsManager.new(
          project: @project,
          shared: @shared
        ).restore
      rescue StandardError => e
        @shared.error(e)
        false
      end
    end
  end
end
