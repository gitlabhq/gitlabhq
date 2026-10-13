# frozen_string_literal: true

module Namespaces
  # Chooses the backend for a group listing or search. Params are passed through rather
  # than allowlisted, because an allowlist would silently drop any param GroupsFinder
  # understands but this class has not been taught about.
  class GroupsFinder
    include ::Gitlab::Utils::StrongMemoize

    attr_reader :current_user, :params

    def initialize(current_user = nil, params = {})
      @current_user = current_user
      # GroupsFinder is handed params untouched, and `to_h` on unpermitted
      # ActionController::Parameters raises, so only plain hashes are normalized.
      @params = params.is_a?(Hash) ? params.symbolize_keys : params
    end

    def execute
      return ::Group.none if unreadable_parent_requested?

      from_elasticsearch || from_postgresql
    end

    private

    # GroupsFinder ignores parent_id, so resolve it here. An unreadable id must return
    # nothing rather than dropping the filter and widening the query.
    def unreadable_parent_requested?
      params[:parent_id].present? && resolved_parent.nil?
    end

    def resolved_parent
      # rubocop: disable CodeReuse/Finder -- GroupFinder is the read_group-checked lookup
      ::GroupFinder.new(current_user).execute(id: params[:parent_id])
      # rubocop: enable CodeReuse/Finder
    end
    strong_memoize_attr :resolved_parent

    def finder_params
      return params if params[:parent_id].blank?

      params.except(:parent_id).merge(parent: resolved_parent)
    end
    strong_memoize_attr :finder_params

    # nil when Elasticsearch cannot serve the request.
    def from_elasticsearch
      return unless advanced_finder.use_elasticsearch_finder?

      advanced_finder.execute
    end

    def from_postgresql
      # rubocop: disable CodeReuse/Finder -- delegating keeps both finders in lockstep
      ::GroupsFinder.new(current_user, finder_params).execute
      # rubocop: enable CodeReuse/Finder
    end

    def advanced_finder
      # rubocop: disable CodeReuse/Finder -- backend selection is this finder's job
      ::Search::AdvancedFinders::GroupsFinder.new(current_user, finder_params)
      # rubocop: enable CodeReuse/Finder
    end
    strong_memoize_attr :advanced_finder
  end
end
