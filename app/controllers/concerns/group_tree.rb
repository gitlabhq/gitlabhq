# frozen_string_literal: true

module GroupTree
  include Gitlab::Utils::StrongMemoize

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  # rubocop: disable CodeReuse/ActiveRecord
  def render_group_tree(groups)
    groups = groups.sort_by_attribute(@sort = safe_params[:sort])

    groups = if search_descendants?
               filtered_groups_with_ancestors(groups)
             elsif safe_params[:parent_id].present?
               groups.where(parent_id: safe_params[:parent_id]).page(safe_params[:page])
             else
               # If `safe_params[:parent_id]` is `nil`, we will only show root-groups
               groups.by_parent(nil).page(safe_params[:page])
             end

    @groups = groups.with_selects_for_list(archived: safe_params[:archived], active: safe_params[:active])

    respond_to do |format|
      format.html
      format.json do
        serializer = GroupChildSerializer.new(current_user: current_user)
                       .with_pagination(request, response)

        serializer.expand_hierarchy if search_descendants?

        render json: serializer.represent(@groups, {
          upto_preloaded_ancestors_only: inactive?
        })
      end
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def filtered_groups_with_ancestors(groups)
    filtered_groups = groups.search(safe_params[:filter]).page(safe_params[:page])

    # We find the ancestors by ID of the search results here.
    # Otherwise the ancestors would also have filters applied,
    # which would cause them not to be preloaded.
    #
    # Pagination needs to be applied before loading the ancestors to
    # make sure ancestors are not cut off by pagination.
    ancestors = Group.where(id: filtered_groups.select(:id)).self_and_ancestors
    ancestors = ancestors.self_or_ancestors_inactive if inactive?
    ancestors
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def inactive?
    safe_params[:active] == false
  end

  def search_descendants?
    safe_params[:filter].present? || inactive?
  end

  def safe_params
    params.merge(
      active: Gitlab::Utils.to_boolean(params[:active]),
      archived: Gitlab::Utils.to_boolean(params[:archived], default: params[:archived])
    ).permit(:sort, :filter, :parent_id, :page, :archived, :active)
  end
  strong_memoize_attr :safe_params
end
