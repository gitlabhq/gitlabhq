# frozen_string_literal: true

module Gitlab
  module Audit
    class NullAuthor
      attr_reader :id, :name

      # Creates an Author
      #
      # While tracking events that could take place even when
      # a user is not logged in, (eg: downloading repo of a public project),
      # we set the author_id of such events as -1
      #
      # @param [Integer] id
      # @param [String] name
      #
      # @return [Gitlab::Audit::UnauthenticatedAuthor, Gitlab::Audit::DeletedAuthor, Gitlab::Audit::RunnerRegistrationTokenAuthor]
      def self.for(id, audit_event)
        name = audit_event[:author_name] || audit_event.details[:author_name]

        if audit_event.details.include?(:runner_registration_token)
          ::Gitlab::Audit::RunnerRegistrationTokenAuthor.new(
            token: audit_event.details[:runner_registration_token],
            entity_type: audit_event.entity_type || audit_event.details[:entity_type],
            entity_path: audit_event.entity_path || audit_event.details[:entity_path]
          )
        elsif id == -1
          Gitlab::Audit::UnauthenticatedAuthor.new(name: name)
        else
          Gitlab::Audit::DeletedAuthor.new(id: id, name: name)
        end
      end

      def initialize(id:, name:)
        @id = id
        @name = name
      end

      def current_sign_in_ip
        nil
      end

      def full_path
        nil
      end
    end
  end
end
