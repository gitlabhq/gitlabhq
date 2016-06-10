# Provides a base class for Admin controllers to subclass
#
# Automatically sets the layout and ensures an administrator is logged in
class Admin::ApplicationController < ApplicationController
  include ActionView::Helpers::UrlHelper
  before_action :authenticate_admin!
  before_action :display_geo_information
  layout 'admin'

  def authenticate_admin!
    render_404 unless current_user.is_admin?
  end

  def display_geo_information
    return unless Gitlab::Geo.secondary?
    primary_node = link_to('primary node', Gitlab::Geo.primary_node.url)
    flash.now[:notice] = "You are in a Geo secondary node (read-only). To make any change you must visit the #{primary_node}.".html_safe
  end
end
