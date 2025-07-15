# frozen_string_literal: true

module Organizations
  class GroupsController < ApplicationController
    include ::Groups::Params

    feature_category :organization
    urgency :low, [:create, :new, :destroy]

    before_action :authorize_create_group!, only: [:new]
    before_action :authorize_read_organization!, only: [:edit]
    before_action :authorize_view_edit_page!, only: [:edit]
    before_action :authorize_remove_group!, only: :destroy

    def new; end

    def edit; end

    def create
      response = create_group
      @group = response[:group]

      if response.success?
        render json: GroupSerializer.new(current_user: current_user).represent(@group)
      else
        render json: { message: @group.errors }, status: :unprocessable_entity
      end
    end

    def destroy
      if group.self_deletion_scheduled? &&
          ::Gitlab::Utils.to_boolean(params.permit(:permanently_remove)[:permanently_remove])
        return destroy_immediately
      end

      result = ::Groups::MarkForDeletionService.new(group, current_user).execute

      if result[:status] == :success
        removal_time = helpers.permanent_deletion_date_formatted
        message = _("'%{group_name}' has been scheduled for removal on %{removal_time}.")

        render json: { message: format(message, group_name: group.name, removal_time: removal_time) }
      else
        render json: { message: result[:message] }, status: :unprocessable_entity
      end
    end

    private

    def group
      @group ||= Group.in_organization(organization).find_by_full_path(params.permit(:id)[:id])
    end

    def create_group
      create_service_params = group_params.merge(organization_id: organization.id)
      Groups::CreateService.new(current_user, create_service_params).execute
    end

    def authorize_view_edit_page!
      return render_404 if group.nil?

      access_denied! unless can?(current_user, :view_edit_page, group)
    end

    def authorize_remove_group!
      return render_404 if group.nil?

      access_denied! unless can?(current_user, :remove_group, group)
    end

    def destroy_immediately
      Groups::DestroyService.new(group, current_user).async_execute
      render json: { message: format(_("Group '%{group_name}' is being deleted."), group_name: group.full_name) }
    rescue Groups::DestroyService::DestroyError => error
      render json: { message: error.message }, status: :unprocessable_entity
    end
  end
end

Organizations::GroupsController.prepend_mod
