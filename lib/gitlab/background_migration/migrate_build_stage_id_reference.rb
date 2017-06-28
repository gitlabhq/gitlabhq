module Gitlab
  module BackgroundMigration
    class MigrateBuildStageIdReference
      class Build < ActiveRecord::Base
        self.table_name = 'ci_builds'
      end

      class Stage < ActiveRecord::Base
        self.table_name = 'ci_stages'
      end

      def perform(id)
      end
    end
  end
end
