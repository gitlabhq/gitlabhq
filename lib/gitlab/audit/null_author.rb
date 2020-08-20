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
      # @return [Gitlab::Audit::UnauthenticatedAuthor, Gitlab::Audit::DeletedAuthor]
      def self.for(id, name)
        if id == -1
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
    end
  end
end
