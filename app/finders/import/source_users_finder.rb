# frozen_string_literal: true

module Import
  class SourceUsersFinder
    def initialize(namespace, current_user, params = {})
      @namespace = namespace
      @current_user = current_user
      @params = params
    end

    def execute
      return Import::SourceUser.none unless authorized?

      namespace.import_source_users
    end

    private

    attr_reader :namespace, :current_user, :params

    def authorized?
      Ability.allowed?(current_user, :admin_namespace, namespace)
    end
  end
end
