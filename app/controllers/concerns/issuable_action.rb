module IssuableAction
  extend ActiveSupport::Concern

  def destroy
    issuable = @merge_request || @issue

    unless current_user.can?(:"remove_#{issuable.to_ability_name}", issuable)
      return access_denied!
    end

    issuable.destroy

    route = polymorphic_path([@project.namespace.becomes(Namespace), @project, issuable.class])
    issuable_name = issuable.class.name.underscore.tr('_', ' ')

    respond_to do |format|
      format.html { redirect_to route, notice: "This #{issuable_name} was deleted." }
      format.json { head :ok }
    end
  end
end
