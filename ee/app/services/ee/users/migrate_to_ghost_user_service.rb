module EE
  module Users
    module MigrateToGhostUserService
      private

      def migrate_records
        migrate_epics
        migrate_vulnerability_feedback
        super
      end

      def migrate_epics
        user.epics.update_all(author_id: ghost_user.id)
        ::Epic.where(last_edited_by_id: user.id).update_all(last_edited_by_id: ghost_user.id)
      end

      def migrate_vulnerability_feedback
        user.vulnerability_feedback.update_all(author_id: ghost_user.id)
      end
    end
  end
end
