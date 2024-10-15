# frozen_string_literal: true

module Projects
  # rubocop: disable Search/NamespacedClass -- not related to global search
  module SearchFilter
    private

    def by_search(items)
      params[:search] ||= params[:name]

      return items if Feature.enabled?(:disable_anonymous_project_search, type: :ops) && current_user.nil? # rubocop:disable Gitlab/FeatureFlagWithoutActor -- feature flag is for anonymous users so no actor available

      if params[:search].present? &&
          params[:minimum_search_length].present? &&
          params[:search].length < params[:minimum_search_length].to_i
        return items.none
      end

      items.optionally_search(params[:search], include_namespace: params[:search_namespaces].present?)
    end
  end
  # rubocop: enable Search/NamespacedClass
end
