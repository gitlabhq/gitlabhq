# frozen_string_literal: true

module Import
  class DeletePlaceholderUserWorker
    include ApplicationWorker

    data_consistency :delayed
    idempotent!
    feature_category :importers
    concurrency_limit -> { 20 }

    def perform(placeholder_user_id, _params = {})
      placeholder_user = find_placeholder_user(placeholder_user_id)
      return unless placeholder_user

      if placeholder_user_referenced?(placeholder_user_id)
        log_placeholder_user_not_deleted(placeholder_user_id)
        return
      end

      placeholder_user.delete_async(
        deleted_by: placeholder_user,
        params: { "skip_authorization" => true }
      )
    end

    private

    def find_placeholder_user(id)
      user = User.find_by_id(id)
      return if user.nil? || !user.placeholder?

      user
    end

    def log_placeholder_user_not_deleted(placeholder_user_id)
      ::Import::Framework::Logger.warn(
        message: 'Unable to delete placeholder user because it is still referenced in other tables',
        placeholder_user_id: placeholder_user_id
      )
    end

    def placeholder_user_referenced?(placeholder_user_id)
      PlaceholderReferences::AliasResolver.models_with_data.any? do |model, data|
        columns = data[:columns].values - data[:columns_ignored_on_deletion].to_a
        (columns & ::Gitlab::ImportExport::Base::RelationFactory::USER_REFERENCES).any? do |user_reference_column|
          model.where(user_reference_column => placeholder_user_id).any? # rubocop:disable CodeReuse/ActiveRecord -- Adding a scope for all possible models would not be feasible here
        end
      end
    end
  end
end
