# frozen_string_literal: true

module Geo
  class RepositoryVerificationReset
    def initialize(type)
      @type = type
    end

    def execute
      return unless Gitlab::Geo.geo_database_configured?
      return unless Gitlab::Geo.secondary?

      raise ArgumentError, "Invalid type: '#{type.inspect}'" unless valid_type?

      num_updated = 0

      Geo::ProjectRegistry
        .where(verification_failed.or(checksum_mismatch))
        .select(:id)
        .each_batch { |relation| num_updated += relation.update_all(updates) }

      num_updated
    end

    private

    attr_reader :type

    def valid_type?
      Geo::ProjectRegistry::REGISTRY_TYPES.include?(type.to_sym)
    end

    def project_registry
      Geo::ProjectRegistry.arel_table
    end

    def checksum_mismatch
      project_registry["#{type}_checksum_mismatch"].eq(true)
    end

    def verification_failed
      project_registry["last_#{type}_verification_failure"].not_eq(nil)
    end

    def updates
      {
        "resync_#{type}" => true,
        "#{type}_verification_checksum_sha" => nil,
        "#{type}_checksum_mismatch" => false,
        "last_#{type}_verification_failure" => nil,
        "#{type}_verification_retry_count" => nil,
        "#{type}_missing_on_primary" => nil
      }
    end
  end
end
