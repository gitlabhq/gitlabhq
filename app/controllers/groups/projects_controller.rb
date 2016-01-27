class Groups::ProjectsController < Groups::ApplicationController
  include ProjectsListing

  skip_before_action :authenticate_user!, only: [:index]

  # Authorize
  before_action :authorize_admin_group!, only: [:edit]

  before_action :init_filter_and_sort, only: [:index]

  layout :determine_layout

  def index
    @projects =
      if current_user
        prepare_for_listing(find_scoped_project(params[:scope]))
      else
        find_projects
      end
  end

  def edit
    @projects = @group.projects.page(params[:page])
  end

  private

  def find_scoped_project(scope)
    case scope
    when 'contributed'
      ContributedProjectsFinder.new(current_user).
        execute(current_user).in_namespace(@group.id)
    when 'starred'
      current_user.starred_projects.in_namespace(@group.id)
    else
      find_projects
    end
  end

  def determine_layout
    if action_name.to_sym == :edit
      'group_settings'
    else
      'group'
    end
  end

end
