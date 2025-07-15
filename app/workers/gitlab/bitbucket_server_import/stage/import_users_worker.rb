# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Stage
      class ImportUsersWorker
        include StageMethods

        resumes_work_when_interrupted!

        idempotent!

        private

        def import(project); end

        def importer_class
          Importers::UsersImporter
        end
      end
    end
  end
end
