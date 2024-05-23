# frozen_string_literal: true

module BulkImports
  class UserContributionsExportMapper
    USER_CONTRIBUTIONS_CACHE_KEY = 'bulk_imports/%{portable_class}/%{portable_id}/user_contribution_ids'

    def initialize(portable)
      @portable_class = portable.class
      @portable_id = portable.id
    end

    def cache_user_contributions_on_record(record)
      return if !record || record.is_a?(User)

      user_references = record.attribute_names & ::Gitlab::ImportExport::Base::RelationFactory::USER_REFERENCES
      return if user_references.empty?

      user_ids = user_references.filter_map { |reference| record.try(reference) }
      import_cache.set_add(generate_cache_key, user_ids, timeout: timeout) if user_ids.present?
    end

    def get_contributing_users
      user_ids = import_cache.values_from_set(generate_cache_key)
      User.by_ids(user_ids)
    end

    def clear_cache
      import_cache.expire(generate_cache_key, 0)
    end

    private

    attr_reader :portable_class, :portable_id

    def generate_cache_key
      Kernel.format(USER_CONTRIBUTIONS_CACHE_KEY, portable_class: portable_class, portable_id: portable_id)
    end

    def import_cache
      Gitlab::Cache::Import::Caching
    end

    def timeout
      ::Gitlab::Cache::Import::Caching::LONGER_TIMEOUT
    end
  end
end
