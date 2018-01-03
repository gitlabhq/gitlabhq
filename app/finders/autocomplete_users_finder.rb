class AutocompleteUsersFinder
  attr_reader :current_user, :project, :group, :search, :skip_users,
              :page, :per_page, :author_id, :params

  def initialize(params:, current_user:, project:, group:)
    @current_user = current_user
    @project = project
    @group = group
    @search = params[:search]
    @skip_users = params[:skip_users]
    @page = params[:page]
    @per_page = params[:per_page]
    @author_id = params[:author_id]
    @params = params
  end

  def execute
    items = find_users
    items = items.active
    items = items.reorder(:name)
    items = items.search(search) if search.present?
    items = items.where.not(id: skip_users) if skip_users.present?
    items = items.page(page).per(per_page)

    if params[:todo_filter].present? && current_user
      items = items.todo_authors(current_user.id, params[:todo_state_filter])
    end

    if search.blank?
      # Include current user if available to filter by "Me"
      if params[:current_user].present? && current_user
        items = [current_user, *items].uniq
      end

      if author_id.present? && current_user
        author = User.find_by_id(author_id)
        items = [author, *items].uniq if author
      end
    end

    items
  end

  private

  def find_users
    return users_from_project if project
    return group.users_with_parents if group
    return User.all if current_user

    User.none
  end

  def users_from_project
    user_ids = project.team.users.pluck(:id)
    user_ids << author_id if author_id.present?

    User.where(id: user_ids)
  end
end
