# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class IssuesImporter
        include ParallelScheduling

        def initialize(project, client, parallel: true)
          super

          @work_item_type_id = ::WorkItems::Type.default_issue_type.id
        end

        def importer_class
          IssueAndLabelLinksImporter
        end

        def representation_class
          Representation::Issue
        end

        def sidekiq_worker_class
          ImportIssueWorker
        end

        def object_type
          :issue
        end

        def collection_method
          :issues
        end

        def id_for_already_imported_cache(issue)
          issue[:number]
        end

        def collection_options
          { state: 'all', sort: 'created', direction: 'asc' }
        end

        def increment_object_counter?(object)
          object[:pull_request].nil?
        end

        private

        def additional_object_data
          { work_item_type_id: @work_item_type_id }
        end
      end
    end
  end
end
