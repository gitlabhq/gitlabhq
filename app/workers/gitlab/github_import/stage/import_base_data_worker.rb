# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportBaseDataWorker
        include ApplicationWorker
        include GithubImport::Queue
        include StageMethods

        # These importers are fast enough that we can just run them in the same
        # thread.
        IMPORTERS = [
          Importer::LabelsImporter,
          Importer::MilestonesImporter,
          Importer::ReleasesImporter
        ].freeze

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          IMPORTERS.each do |klass|
            klass.new(project, client).execute
          end

          project.refresh_import_jid_expiration

          ImportPullRequestsWorker.perform_async(project.id)
        end
      end
    end
  end
end
