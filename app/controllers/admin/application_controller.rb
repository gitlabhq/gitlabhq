# Provides a base class for Admin controllers to subclass
#
# Automatically sets the layout and ensures an administrator is logged in
class Admin::ApplicationController < ApplicationController
  before_action :authenticate_admin!
  before_action :display_readonly_information
  layout 'admin'

  def authenticate_admin!
    render_404 unless current_user.admin?
  end

  def display_readonly_information
    return unless Gitlab::Database.readonly?

    flash.now[:notice] = readonly_message
  end

  private

  # Overridden in EE
  def readonly_message
    _('You are on a read-only GitLab instance.').html_safe
  end
end
