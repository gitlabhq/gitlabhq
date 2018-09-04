module EE
  module RepositoryCheck
    module BatchWorker
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      private

      override :never_checked_project_ids
      # rubocop: disable CodeReuse/ActiveRecord
      def never_checked_project_ids(batch_size)
        return super unless ::Gitlab::Geo.secondary?

        Geo::ProjectRegistry.synced_repos.synced_wikis
          .where(last_repository_check_at: nil)
          .where('last_repository_synced_at < ?', 24.hours.ago)
          .where('last_wiki_synced_at < ?', 24.hours.ago)
          .limit(batch_size).pluck(:project_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      override :old_checked_project_ids
      # rubocop: disable CodeReuse/ActiveRecord
      def old_checked_project_ids(batch_size)
        return super unless ::Gitlab::Geo.secondary?

        Geo::ProjectRegistry.synced_repos.synced_wikis
          .where('last_repository_check_at < ?', 1.month.ago)
          .reorder(last_repository_check_at: :asc)
          .limit(batch_size).pluck(:project_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
