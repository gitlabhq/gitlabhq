# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # No OP for CE
    class FixOrphanPromotedIssues
      def perform(note_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::FixOrphanPromotedIssues.prepend_if_ee('EE::Gitlab::BackgroundMigration::FixOrphanPromotedIssues')
