# frozen_string_literal: true

module GroupTree
  include Gitlab::Utils::StrongMemoize

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def render_group_tree(groups)
    groups = groups.sort_by_attribute(@sort = safe_params[:sort])

    if search_descendants?
      pagination_resource = filtered_groups_with_id_only(groups)
      @groups = groups_with_ancestors(pagination_resource.map(&:id))
    elsif safe_params[:parent_id].present?
      @groups = subgroups(groups)
    else
      @groups = root_groups(groups)
    end

    respond_to do |format|
      format.html
      format.json do
        serializer = GroupChildSerializer.new(current_user: current_user)
                       .with_pagination(request, response)

        serializer.expand_hierarchy if search_descendants?

        render json: serializer.represent(@groups, {
          upto_preloaded_ancestors_only: inactive?,
          pagination_resource: pagination_resource
        })
      end
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord -- requires specialized queries
  def subgroups(groups)
    query = groups.where(parent_id: safe_params[:parent_id]).with_selects_for_list
    paginate(query)
  end

  def root_groups(groups)
    query = groups.by_parent(nil).with_selects_for_list
    paginate(query)
  end

  def filtered_groups_with_id_only(groups)
    paginate(groups.select(:id).search(safe_params[:filter]))
  end

  def groups_with_ancestors(group_ids)
    # We find the ancestors by ID of the search results here.
    # Otherwise the ancestors would also have filters applied,
    # which would cause them not to be preloaded.
    #
    # Pagination needs to be applied before loading the ancestors to
    # make sure ancestors are not cut off by pagination.
    ancestors = Group.where(id: group_ids).self_and_ancestors
    ancestors = ancestors.self_or_ancestors_inactive if inactive?
    ancestors.with_selects_for_list
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def paginate(group)
    return group.page(safe_params[:page]).per(per_page) unless keyset_pagination?

    group.keyset_paginate(cursor: safe_params[:cursor], per_page: per_page)
  end

  def per_page
    Kaminari.config.default_per_page
  end

  def inactive?
    safe_params[:active] == false
  end

  def keyset_pagination?
    safe_params[:pagination] == 'keyset'
  end

  def search_descendants?
    safe_params[:filter].present? || inactive?
  end

  def safe_params
    params.merge(
      active: Gitlab::Utils.to_boolean(params[:active]),
      archived: Gitlab::Utils.to_boolean(params[:archived], default: params[:archived])
    ).permit(:sort, :filter, :parent_id, :page, :archived, :active, :cursor, :pagination)
  end
  strong_memoize_attr :safe_params
end
