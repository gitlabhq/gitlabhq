# frozen_string_literal: true

module DesignManagement
  class VersionsFinder
    attr_reader :design_or_collection, :current_user, :params

    # The `design_or_collection` argument should be either a:
    #
    # - DesignManagement::Design, or
    # - DesignManagement::DesignCollection
    #
    # The object will have `#versions` called on it to set up the
    # initial scope of the versions.
    #
    # valid params:
    #   - earlier_or_equal_to: Version
    #   - sha: String
    #   - version_id: Integer
    #
    def initialize(design_or_collection, current_user, params = {})
      @design_or_collection = design_or_collection
      @current_user = current_user
      @params = params
    end

    def execute
      return DesignManagement::Version.none unless Ability.allowed?(current_user, :read_design, design_or_collection)

      items = design_or_collection.versions
      items = by_earlier_or_equal_to(items)
      items = by_sha(items)
      items = by_version_id(items)
      items.ordered
    end

    private

    def by_earlier_or_equal_to(items)
      return items unless params[:earlier_or_equal_to]

      items.earlier_or_equal_to(params[:earlier_or_equal_to])
    end

    def by_version_id(items)
      return items unless params[:version_id]

      items.id_in(params[:version_id])
    end

    def by_sha(items)
      return items unless params[:sha]

      items.by_sha(params[:sha])
    end
  end
end
