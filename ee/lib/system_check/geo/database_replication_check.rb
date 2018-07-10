module SystemCheck
  module Geo
    class DatabaseReplicationCheck < SystemCheck::BaseCheck
      set_name 'Using database streaming replication?'
      set_skip_reason 'not a secondary node'

      def skip?
        !Gitlab::Geo.secondary?
      end

      def check?
        Gitlab::Database.db_read_only?
      end

      def show_error
        try_fixing_it(
          'Follow Geo setup instructions to configure primary and secondary nodes for streaming replication'
        )

        for_more_information('doc/gitlab-geo/database.md')
      end
    end
  end
end
