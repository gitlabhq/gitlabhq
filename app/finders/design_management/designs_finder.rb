# frozen_string_literal: true

module DesignManagement
  class DesignsFinder
    include Gitlab::Allowable
    include FinderMethods

    # Params:
    # ids: integer[]
    # filenames: string[]
    # visible_at_version: ?version
    # filenames: String[]
    def initialize(issue, current_user, params = {})
      @issue = issue
      @current_user = current_user
      @params = params
    end

    def execute
      items = init_collection

      items = by_visible_at_version(items)
      items = by_filename(items)
      items = by_id(items)
      items.ordered
    end

    private

    attr_reader :issue, :current_user, :params

    def init_collection
      return DesignManagement::Design.none unless can?(current_user, :read_design, issue)

      issue.designs
    end

    # Returns all designs that existed at a particular design version,
    # where `nil` means `at-current-version`.
    def by_visible_at_version(items)
      items.visible_at_version(params[:visible_at_version])
    end

    def by_filename(items)
      return items if params[:filenames].nil?
      return DesignManagement::Design.none if params[:filenames].empty?

      items.with_filename(params[:filenames])
    end

    def by_id(items)
      return items if params[:ids].nil?
      return DesignManagement::Design.none if params[:ids].empty?

      items.id_in(params[:ids])
    end
  end
end
