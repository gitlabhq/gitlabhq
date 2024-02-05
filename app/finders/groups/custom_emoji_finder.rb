# frozen_string_literal: true

module Groups
  class CustomEmojiFinder < Base
    include FinderWithGroupHierarchy
    include Gitlab::Utils::StrongMemoize

    def initialize(group, params = {})
      @group = group
      @params = params
      @skip_authorization = true
    end

    def execute
      return CustomEmoji.for_resource(group) unless params[:include_ancestor_groups]

      CustomEmoji.for_namespaces(group_ids_for(group))
    end

    private

    attr_reader :group, :params, :skip_authorization
  end
end
