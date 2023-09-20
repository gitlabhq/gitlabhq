# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module ErrorTracking
      def track_import_failure!(project, exception:, **args)
        Gitlab::Import::ImportFailureService.track(
          project_id: project.id,
          error_source: self.class.name,
          exception: exception,
          **args
        )
      end
    end
  end
end
