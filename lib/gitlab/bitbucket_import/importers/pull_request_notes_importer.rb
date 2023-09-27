# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Importers
      class PullRequestNotesImporter
        include Loggable
        include ErrorTracking

        def initialize(project, hash)
          @project = project
          @importer = Gitlab::BitbucketImport::Importer.new(project)
          @object = hash.with_indifferent_access
        end

        def execute
          log_info(import_stage: 'import_pull_request_notes', message: 'starting', iid: object[:iid])

          merge_request = project.merge_requests.find_by(iid: object[:iid]) # rubocop: disable CodeReuse/ActiveRecord

          importer.import_pull_request_comments(merge_request, merge_request) if merge_request

          log_info(import_stage: 'import_pull_request_notes', message: 'finished', iid: object[:iid])
        rescue StandardError => e
          track_import_failure!(project, exception: e)
        end

        private

        attr_reader :object, :project, :importer
      end
    end
  end
end
