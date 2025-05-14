# frozen_string_literal: true

module Groups
  class ChildrenController < Groups::ApplicationController
    include Gitlab::Utils::StrongMemoize
    extend ::Gitlab::Utils::Override

    before_action :group
    before_action :validate_per_page

    skip_cross_project_access_check :index

    feature_category :groups_and_projects

    # TODO: Set to higher urgency after resolving https://gitlab.com/gitlab-org/gitlab/-/issues/331494
    urgency :low, [:index]

    def index
      return render_404 if parent.nil?

      respond_to do |format|
        format.json do
          serializer = GroupChildSerializer
                         .new(current_user: current_user)
                         .with_pagination(request, response)
          serializer.expand_hierarchy(parent) if params[:filter].present?
          render json: serializer.represent(children)
        end
      end
    end

    private

    override :has_project_list?
    def has_project_list?
      true
    end

    def parent
      return @group unless params[:parent_id].present?

      GroupFinder.new(current_user).execute(id: params[:parent_id])
    end
    strong_memoize_attr :parent

    def children
      @children = GroupDescendantsFinder.new(
        current_user: current_user,
        parent_group: parent,
        params: descendants_params
      ).execute
    end

    def descendants_params
      params_copy = safe_params.merge(
        sort: safe_params[:sort] || @group_projects_sort,
        active: Gitlab::Utils.to_boolean(safe_params[:active]),
        archived: Gitlab::Utils.to_boolean(safe_params[:archived], default: safe_params[:archived]),
        not_aimed_for_deletion: Gitlab::Utils.to_boolean(safe_params[:not_aimed_for_deletion])
      )
      params_copy.delete(:active) unless filter_active?
      params_copy.compact
    end

    def validate_per_page
      return unless params.key?(:per_page)

      per_page = begin
        Integer(params[:per_page])
      rescue ArgumentError, TypeError
        0
      end

      respond_to do |format|
        format.json do
          render status: :bad_request, json: { message: 'per_page does not have a valid value' } if per_page < 1
        end
      end
    end

    def filter_active?
      return false unless Feature.enabled?(:group_descendants_active_filter, current_user)

      parent.active?
    end
  end
end
