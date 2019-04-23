# frozen_string_literal: true
module Gitlab
  module PhabricatorImport
    class ImportTasksWorker < BaseWorker
      def importer_class
        Gitlab::PhabricatorImport::Issues::Importer
      end
    end
  end
end
