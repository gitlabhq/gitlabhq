# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportRepositoryWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        include StageMethods

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          info(project.id, message: "starting importer", importer: 'Importer::RepositoryImporter')

          # If a user creates a record while the import is in progress, this can lead to an import failure
          # due to IID conflicts. Pre-allocating IIDs for all relevant resources prevents this.
          preallocate_iids!(project, client)

          importer = Importer::RepositoryImporter.new(project, client)

          importer.execute

          counter.increment

          ImportBaseDataWorker.perform_async(project.id)
        end

        def counter
          Gitlab::Metrics.counter(
            :github_importer_imported_repositories,
            'The number of imported GitHub repositories'
          )
        end

        private

        def preallocate_iids!(project, client)
          max_iids = {}

          # On retries, skip GitHub API calls for resources whose IIDs have
          # already been allocated to avoid unnecessary rate-limit consumption.
          collect_issue_iids(project, client, max_iids)
          collect_merge_request_iids(project, client, max_iids)
          collect_milestone_iids(project, client, max_iids)

          return if max_iids.empty?

          Gitlab::Import::IidPreallocator.new(project, max_iids).execute
        end

        def collect_issue_iids(project, client, max_iids)
          return if iid_allocated?(project, :issues)

          max_issue_number = fetch_max_issue_number(project, client)
          max_iids[:issues] = max_issue_number if max_issue_number
        end

        def collect_merge_request_iids(project, client, max_iids)
          return if iid_allocated?(project, :merge_requests)

          max_pr_number = fetch_max_pull_request_number(project, client)
          max_iids[:merge_requests] = max_pr_number if max_pr_number
        end

        def collect_milestone_iids(project, client, max_iids)
          return if iid_allocated?(project, :milestones)

          max_milestone_number = fetch_max_milestone_number(project, client)
          max_iids[:project_milestones] = max_milestone_number if max_milestone_number
        end

        def iid_allocated?(project, usage)
          # Issue IIDs are scoped to the project namespace, not the project itself.
          # Other resources (merge requests, milestones) are scoped to the project.
          scope = usage == :issues ? { namespace: project.project_namespace } : { project: project }

          InternalId.exists?(**scope, usage: usage) # rubocop: disable CodeReuse/ActiveRecord -- lightweight existence check
        end

        def fetch_max_issue_number(project, client)
          options = { state: 'all', sort: 'number', direction: 'desc', per_page: '1' }
          last_github_issue = client.each_object(:issues, project.import_source, options).first

          last_github_issue&.fetch(:number, nil)
        end

        def fetch_max_pull_request_number(project, client)
          options = { state: 'all', sort: 'created', direction: 'desc', per_page: '1' }
          last_github_pr = client.each_object(:pull_requests, project.import_source, options).first

          last_github_pr&.fetch(:number, nil)
        end

        # The GitHub Milestones API does not support sorting by number,
        # so we fetch all milestones and compute the max client-side.
        def fetch_max_milestone_number(project, client)
          max_number = nil

          client.each_object(:milestones, project.import_source, { state: 'all', per_page: '100' }) do |milestone|
            number = milestone[:number]
            max_number = number if number && (max_number.nil? || number > max_number)
          end

          max_number
        end
      end
    end
  end
end
