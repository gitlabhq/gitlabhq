# frozen_string_literal: true

module Gitlab
  module Audit
    class NullAuthor
      UNAUTHENTICATED_AUTHOR_ID = -1
      DEPLOY_TOKEN_AUTHOR_ID = -2
      DEPLOY_KEY_AUTHOR_ID = -3
      ORBIT_INDEXER_AUTHOR_ID = -4

      attr_reader :id, :name

      # Creates an Author
      #
      # While tracking events that could take place even when
      # a user is not logged in, (eg: downloading repo of a public project),
      # we set the author_id of such events as -1
      #
      # @param [Integer] id
      # @param [String] name
      # rubocop: disable Layout/LineLength
      # @return [Gitlab::Audit::UnauthenticatedAuthor, Gitlab::Audit::DeletedAuthor, Gitlab::Audit::CiRunnerTokenAuthor, Gitlab::Audit::DeployTokenAuthor]
      def self.for(id, audit_event)
        name = audit_event[:author_name] || audit_event.details[:author_name]

        if audit_event.target_type == ::Ci::Runner.name
          Gitlab::Audit::CiRunnerTokenAuthor.new(
            entity_type: audit_event.entity_type, entity_path: audit_event.entity_path,
            **audit_event.details.slice(:runner_authentication_token, :runner_registration_token).symbolize_keys
          )
        elsif id == UNAUTHENTICATED_AUTHOR_ID
          Gitlab::Audit::UnauthenticatedAuthor.new(name: name)
        elsif id == DEPLOY_TOKEN_AUTHOR_ID
          Gitlab::Audit::DeployTokenAuthor.new(name: name)
        elsif id == DEPLOY_KEY_AUTHOR_ID
          Gitlab::Audit::DeployKeyAuthor.new(name: name)
        elsif id == ORBIT_INDEXER_AUTHOR_ID
          Gitlab::Audit::OrbitIndexerAuthor.new(name: name)
        else
          Gitlab::Audit::DeletedAuthor.new(id: id, name: name)
        end
      end

      def initialize(id:, name:)
        @id = id
        @name = name
      end

      def to_global_id
        "gid://gitlab/ComplianceManagement::NullAuthor/@id"
      end

      def current_sign_in_ip
        nil
      end

      def full_path
        nil
      end

      def impersonated?
        false
      end
    end
  end
end
