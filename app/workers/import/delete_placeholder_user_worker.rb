# frozen_string_literal: true

module Import
  class DeletePlaceholderUserWorker
    include ApplicationWorker

    data_consistency :delayed
    idempotent!
    feature_category :importers

    def perform(source_user_id)
      source_user = Import::SourceUser.find_by_id(source_user_id)
      return if source_user.nil? || source_user.placeholder_user.nil?
      return unless source_user.placeholder_user.placeholder?

      if placeholder_user_referenced?(source_user)
        log_placeholder_user_not_deleted(source_user)
        return
      end

      placeholder_user = source_user.placeholder_user

      placeholder_user.delete_async(
        deleted_by: placeholder_user,
        params: { "skip_authorization" => true }
      )
    end

    private

    def log_placeholder_user_not_deleted(source_user)
      ::Import::Framework::Logger.warn(
        message: 'Unable to delete placeholder user because it is still referenced in other tables',
        source_user_id: source_user.id
      )
    end

    def placeholder_user_referenced?(source_user)
      PlaceholderReferences::AliasResolver.models_with_data.any? do |model, data|
        columns = data[:columns].values - data[:columns_ignored_on_deletion].to_a
        (columns & ::Gitlab::ImportExport::Base::RelationFactory::USER_REFERENCES).any? do |user_reference_column|
          model.where(user_reference_column => source_user.placeholder_user_id).any? # rubocop:disable CodeReuse/ActiveRecord -- Adding a scope for all possible models would not be feasible here
        end
      end
    end
  end
end
