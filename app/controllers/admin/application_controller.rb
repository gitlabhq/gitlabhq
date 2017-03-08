# Provides a base class for Admin controllers to subclass
#
# Automatically sets the layout and ensures an administrator is logged in
class Admin::ApplicationController < ApplicationController
  before_action :authenticate_admin!
  before_action :display_geo_information
  layout 'admin'

  def authenticate_admin!
    render_404 unless current_user.is_admin?
  end

  def display_geo_information
    return unless Gitlab::Geo.secondary?

    primary_node = view_context.link_to('primary node', Gitlab::Geo.primary_node.url)
    flash.now[:notice] = "You are on a secondary (read-only) Geo node. If you want to make any changes, you must visit the #{primary_node}.".html_safe
  end
end
