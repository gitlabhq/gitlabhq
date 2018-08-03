# frozen_string_literal: true

module Geo
  class RepositoryVerificationSecondaryService < BaseRepositoryVerificationService
    def initialize(registry, type)
      @registry = registry
      @type     = type.to_sym
    end

    def execute
      return unless Gitlab::Geo.geo_database_configured?
      return unless Gitlab::Geo.secondary?
      return unless should_verify_checksum?

      verify_checksum
    end

    private

    attr_reader :registry, :type

    delegate :project, to: :registry

    def should_verify_checksum?
      return false if resync?
      return false unless primary_checksum.present?

      mismatch?(secondary_checksum)
    end

    def resync?
      registry.public_send("resync_#{type}") # rubocop:disable GitlabSecurity/PublicSend
    end

    def primary_checksum
      project.repository_state.public_send("#{type}_verification_checksum") # rubocop:disable GitlabSecurity/PublicSend
    end

    def secondary_checksum
      registry.public_send("#{type}_verification_checksum_sha") # rubocop:disable GitlabSecurity/PublicSend
    end

    def mismatch?(checksum)
      primary_checksum != checksum
    end

    def verify_checksum
      checksum = calculate_checksum(repository)

      if mismatch?(checksum)
        update_registry!(mismatch: true, failure: "#{type.to_s.capitalize} checksum mismatch")
      else
        update_registry!(checksum: checksum)
      end
    rescue => e
      update_registry!(failure: "Error calculating #{type} checksum", exception: e)
    end

    def update_registry!(checksum: nil, mismatch: false, failure: nil, exception: nil)
      reverify, verification_retry_count =
        if mismatch || failure.present?
          log_error(failure, exception, type: type)
          [true, registry.verification_retry_count(type) + 1]
        else
          [false, nil]
        end

      resync_retry_at, resync_retry_count =
        if reverify
          [*calculate_next_retry_attempt(registry, type)]
        end

      registry.update!(
        "#{type}_verification_checksum_sha" => checksum,
        "#{type}_checksum_mismatch" => mismatch,
        "last_#{type}_verification_failure" => failure,
        "#{type}_verification_retry_count" => verification_retry_count,
        "resync_#{type}" => reverify,
        "#{type}_retry_at" => resync_retry_at,
        "#{type}_retry_count" => resync_retry_count
      )
    end

    def repository
      @repository ||=
        case type
        when :repository then project.repository
        when :wiki then project.wiki.repository
        end
    end
  end
end
