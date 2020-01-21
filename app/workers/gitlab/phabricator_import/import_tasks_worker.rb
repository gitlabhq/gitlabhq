# frozen_string_literal: true
module Gitlab
  module PhabricatorImport
    class ImportTasksWorker < BaseWorker
      include ApplicationWorker
      include ProjectImportOptions # This marks the project as failed after too many tries

      def importer_class
        Gitlab::PhabricatorImport::Issues::Importer
      end
    end
  end
end
