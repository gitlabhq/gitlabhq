class GroupChildEntity < Grape::Entity
  include ActionView::Helpers::NumberHelper
  include RequestAwareEntity

  expose :id, :name, :description, :visibility, :full_name, :full_path, :web_url,
         :created_at, :updated_at, :star_count, :can_edit, :type, :parent_id,
         :children_count, :leave_path, :edit_path, :number_projects_with_delimiter,
         :number_users_with_delimiter, :permissions, :star_count

  def type
    object.class.name.downcase
  end

  def can_edit
    return false unless request.respond_to?(:current_user)

    can?(request.current_user, "edit_{type}", object)
  end
  expose
end
