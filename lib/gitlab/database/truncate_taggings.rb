# frozen_string_literal: true

module Gitlab
  module Database
    class TruncateTaggings
      include AsyncDdlExclusiveLeaseGuard

      def execute
        return unless Gitlab.com_except_jh? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- it's not a feature
        return unless taggings_has_any_data?

        try_obtain_lease do
          connection.execute('TRUNCATE TABLE "taggings"')
        end
      end

      def taggings_has_any_data?
        !!connection.select_value('SELECT TRUE FROM "taggings" LIMIT 1')
      end

      def connection
        ::Ci::ApplicationRecord.connection
      end

      def connection_db_config
        ::Ci::ApplicationRecord.connection_db_config
      end

      def lease_timeout
        10.minutes
      end
    end
  end
end
