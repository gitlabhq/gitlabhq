class PersonalProjectsFinder
  def initialize(user)
    @user = user
  end

  # Finds the projects belonging to the user in "@user", limited to either
  # public projects or projects visible to the given user.
  #
  # current_user - When given the list of projects is limited to those only
  #                visible by this user.
  #
  # Returns an ActiveRecord::Relation.
  def execute(current_user = nil)
    if current_user
      relation = projects_visible_to_user(current_user)
    else
      relation = public_projects
    end

    relation.includes(:namespace).order_id_desc
  end

  private

  def projects_visible_to_user(current_user)
    authorized = @user.personal_projects.visible_to_user(current_user)

    union = Gitlab::SQL::Union.
      new([authorized.select(:id), public_and_internal_projects.select(:id)])

    Project.where("projects.id IN (#{union.to_sql})")
  end

  def public_projects
    @user.personal_projects.public_only
  end

  def public_and_internal_projects
    @user.personal_projects.public_and_internal_only
  end
end
