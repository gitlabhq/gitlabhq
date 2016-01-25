# == ProjectsListing
#
# Controller concern to handle projects list filtering & sorting
#
# Upon inclusion, calls `load_filter_and_sort` on all actions.
module ProjectsListing
  extend ActiveSupport::Concern

  included do
    before_action :load_filter_and_sort
  end

  private

  def load_filter_and_sort
    @filter = params.fetch(:filter) { 'all' }
    @sort   = params.fetch(:sort)   { 'recently_active' }
  end

  def load_user_projects
    return unless current_user

    @user_projects = prepare_for_listing(current_user.authorized_projects)
  end

  def load_starred_projects
    return unless current_user

    @starred_projects = prepare_for_listing(current_user.starred_projects)
  end

  def prepare_for_listing(relation)
    apply_filter(apply_base_scopes(relation)).sort(@sort)
  end

  def apply_base_scopes(relation)
    relation.non_archived.includes(:namespace)
  end

  def apply_filter(relation)
    if current_user && @filter == 'personal'
      relation.personal(current_user)
    else
      relation
    end
  end

end
