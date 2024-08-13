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

      collection = namespace.import_source_users
      collection = by_statuses(collection)
      collection = by_search(collection)
      sort(collection)
    end

    private

    attr_reader :namespace, :current_user, :params

    def authorized?
      Ability.allowed?(current_user, :admin_namespace, namespace)
    end

    def by_statuses(collection)
      return collection unless params[:statuses].present?

      collection.by_statuses(params[:statuses])
    end

    def by_search(collection)
      return collection unless params[:search].present?

      collection.search(params[:search])
    end

    def sort(collection)
      collection.sort_by_attribute(params[:sort] || :source_name_asc)
    end
  end
end
