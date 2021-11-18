# frozen_string_literal: true

module IssuableLinks
  class ListService
    include Gitlab::Routing

    attr_reader :issuable, :current_user

    def initialize(issuable, user)
      @issuable = issuable
      @current_user = user
    end

    def execute
      serializer.new(current_user: current_user, issuable: issuable)
        .represent(child_issuables, serializer_options)
    end

    private

    def serializer_options
      {}
    end

    def serializer
      raise NotImplementedError
    end

    def preload_for_collection
      [{ project: :namespace }, :assignees]
    end
  end
end
