# frozen_string_literal: true

module Gitlab
  module GlobalAnonymousId
    UNKNOWN_ID = 'unknown'

    # Generates a globally unique user_id. This allows us to anonymously identify even self-managed users and instances
    # that make requests into GitLab infrastructure.
    def self.user_id(user)
      user_id = user&.id

      return UNKNOWN_ID unless user_id
      raise ArgumentError, 'must pass a user instance' unless user.is_a?(User)

      Gitlab::CryptoHelper.sha256("#{instance_id}#{user_id}")
    end

    def self.instance_id
      ::Gitlab::CurrentSettings.uuid.presence || GITLAB_INSTANCE_UUID_NOT_SET
    end
  end
end
