module IssuableActions
  extend ActiveSupport::Concern

  included do
    before_action :authorize_destroy_issuable!, only: :destroy
    before_action :authorize_admin_issuable!, only: :bulk_update
  end

  def destroy
    issuable.destroy

    name = issuable.class.name.titleize.downcase
    flash[:notice] = "The #{name} was successfully deleted."
    redirect_to polymorphic_path([@project.namespace.becomes(Namespace), @project, issuable.class])
  end

  def bulk_update
    result = Issuable::BulkUpdateService.new(project, current_user, bulk_update_params).execute(resource_name)
    quantity = result[:count]

    render json: { notice: "#{quantity} #{resource_name.pluralize(quantity)} updated" }
  end

  private

  def authorize_destroy_issuable!
    unless current_user.can?(:"destroy_#{issuable.to_ability_name}", issuable)
      return access_denied!
    end
  end

  def authorize_admin_issuable!
    unless current_user.can?(:"admin_#{resource_name}", @project)
      return access_denied!
    end
  end

  def bulk_update_params
    params.require(:update).permit(
      :issuable_ids,
      :assignee_id,
      :milestone_id,
      :state_event,
      :subscription_event,
      label_ids: [],
      add_label_ids: [],
      remove_label_ids: []
    )
  end

  def resource_name
    @resource_name ||= controller_name.singularize
  end
end
