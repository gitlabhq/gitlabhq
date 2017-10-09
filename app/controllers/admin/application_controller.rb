# Provides a base class for Admin controllers to subclass
#
# Automatically sets the layout and ensures an administrator is logged in
class Admin::ApplicationController < ApplicationController
  before_action :authenticate_admin!
  before_action :display_read_only_information
  layout 'admin'

  def authenticate_admin!
    render_404 unless current_user.admin?
  end

  def display_read_only_information
    return unless Gitlab::Database.read_only?

    flash.now[:notice] = read_only_message
  end

  private

  # Overridden in EE
  def read_only_message
    _('You are on a read-only GitLab instance.')
  end
end
