module IssuableActions
  extend ActiveSupport::Concern

  included do
    before_action :authorize_destroy_issuable!, only: :destroy
  end

  def destroy
    issuable.destroy

    name = issuable.class.name.titleize.downcase
    flash[:notice] = "The #{name} was successfully deleted."
    redirect_to polymorphic_path([@project.namespace.becomes(Namespace), @project, issuable.class])
  end

  private

  def authorize_destroy_issuable!
    unless current_user.can?(:"destroy_#{issuable.to_ability_name}", issuable)
      return access_denied!
    end
  end
end
