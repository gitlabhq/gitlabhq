# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class creates/updates those namespace statistics
    # that haven't been created nor initialized.
    # It also updates the related namespace statistics
    # This is only required in EE
    class PopulateNamespaceStatistics
      def perform(group_ids, statistics)
      end
    end
  end
end

Gitlab::BackgroundMigration::PopulateNamespaceStatistics.prepend_mod_with('Gitlab::BackgroundMigration::PopulateNamespaceStatistics')
