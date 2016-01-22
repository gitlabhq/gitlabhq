# == AuthenticatesWithTwoFactor
#
# Controller concern to handle projects list filtering & sorting
#
# Upon inclusion, skips `require_no_authentication` on `:create`.
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
    @user_projects = refine_projects(ProjectsFinder.new.execute(current_user))
  end

  def load_starred_projects
    @starred_projects = refine_projects(
      current_user.starred_projects.includes(:forked_from_project)
    )
  end

  def refine_projects(relation)
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
