module Gitlab
  module BackgroundMigration
    class UpdateAuthorizedKeysFileSince
      class Key < ActiveRecord::Base
        self.table_name = 'keys'
      end

      def perform(cutoff_datetime)
        add_keys_since(cutoff_datetime)

        remove_keys_not_found_in_db
      end

      def add_keys_since(cutoff_datetime)
        start_key = Key.select(:id).where("created_at >= ?", cutoff_datetime).take
        if start_key
          GitlabShellWorker.perform_async(:batch_add_keys_in_db_starting_from, start_key.id)
        end
      end

      def remove_keys_not_found_in_db
        GitlabShellWorker.perform_async(:remove_keys_not_found_in_db)
      end
    end
  end
end
