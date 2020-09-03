# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop:disable Style/Documentation
    class PopulateResolvedOnDefaultBranchColumn
      def perform(*); end
    end
  end
end

Gitlab::BackgroundMigration::PopulateResolvedOnDefaultBranchColumn.prepend_if_ee('EE::Gitlab::BackgroundMigration::PopulateResolvedOnDefaultBranchColumn')
