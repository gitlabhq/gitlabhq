class Explore::GroupsController < Explore::ApplicationController
  include GroupTree

  def index
    render_group_tree GroupsFinder.new(current_user).execute
  end
end
