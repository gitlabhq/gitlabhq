# rubocop:disable GitlabSecurity/PublicSend

module Geo
  class RepositoryVerifySecondaryService
    include Gitlab::Geo::RepositoryVerificationLogHelpers

    delegate :project, to: :registry

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

    # This is primarily a guard method, to reduce the chance of false failures (which could happen
    # for repositories that change very rapidly)
    def should_verify_checksum?
      primary_checksum                  = registry.repository_state.public_send("#{type}_verification_checksum")
      secondary_checksum                = registry.public_send("#{type}_verification_checksum")
      primary_last_verification_at      = registry.repository_state.public_send("last_#{type}_verification_at")
      secondary_last_verification_at    = registry.public_send("last_#{type}_verification_at") || Time.at(0)
      secondary_last_successful_sync_at = registry.public_send("last_#{type}_successful_sync_at")

      # primary repository was verified (even if checksum is nil).
      # note: we allow a nil primary checksum so that we will run through the checksum
      # and set the verification date on the secondary.  Otherwise, we'll keep revisiting
      # this record over and over.
      return false if primary_last_verification_at.nil?

      # secondary repository checksum does not equal the primary repository checksum
      return false if secondary_checksum == primary_checksum && !primary_checksum.nil?

      # primary was verified later than the secondary verification
      return false if primary_last_verification_at < secondary_last_verification_at

      # secondary repository was successfully synced after the last secondary verification
      return false if secondary_last_successful_sync_at.nil? || secondary_last_successful_sync_at < secondary_last_verification_at

      true
    end

    private

    attr_reader :registry, :type

    def verify_checksum
      checksum = calculate_checksum(project.repository_storage, repository_path)

      if mismatch?(checksum)
        record_status(error_msg: "#{type.to_s.capitalize} checksum mismatch: #{repository_path}")
      else
        record_status(checksum: checksum)
      end
    rescue ::Gitlab::Git::Repository::NoRepository, ::Gitlab::Git::Checksum::Failure, Timeout::Error => e
      record_status(error_msg: "Error verifying #{type.to_s.capitalize} checksum: #{repository_path}", exception: e)
    end

    def mismatch?(checksum)
      checksum != registry.public_send("project_#{type}_verification_checksum")
    end

    def calculate_checksum(storage, relative_path)
      Gitlab::Git::Checksum.new(storage, relative_path).calculate
    end

    # note: the `last_#{type}_verification_at` is always set, indicating that was the
    # time that we _did_ a verification, success or failure
    def record_status(checksum: nil, error_msg: nil, exception: nil, details: {})
      attrs = {
        "#{type}_verification_checksum"     => checksum,
        "last_#{type}_verification_at"      => DateTime.now,
        "last_#{type}_verification_failure" => nil,
        "last_#{type}_verification_failed"  => false
      }

      if error_msg
        attrs["last_#{type}_verification_failed"]  = true
        attrs["last_#{type}_verification_failure"] = error_msg

        log_error(error_msg, exception, type: type, repository_path: repository_path, full_path: path_to_repo)
      end

      registry.update!(attrs)
    end

    def repository_path
      registry.repository_path(type)
    end

    def path_to_repo
      case type
      when :repository
        project.repository.path_to_repo
      when :wiki
        project.wiki.repository.path_to_repo
      end
    end
  end
end
