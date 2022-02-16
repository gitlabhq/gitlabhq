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
      # @return [Gitlab::Audit::UnauthenticatedAuthor, Gitlab::Audit::DeletedAuthor, Gitlab::Audit::CiRunnerTokenAuthor]
      def self.for(id, audit_event)
        name = audit_event[:author_name] || audit_event.details[:author_name]

        if audit_event.target_type == ::Ci::Runner.name
          Gitlab::Audit::CiRunnerTokenAuthor.new(audit_event)
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
