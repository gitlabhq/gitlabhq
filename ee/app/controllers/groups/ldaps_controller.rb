class Groups::LdapsController < Groups::ApplicationController
  before_action :group
  before_action :authorize_admin_group!
  before_action :check_enabled_extras!

  def sync
    if @group.pending_ldap_sync
      LdapGroupSyncWorker.perform_async(@group.id)
      message = 'The group sync has been scheduled'
    else
      message = 'The group sync is already scheduled'
    end

    redirect_to group_group_members_path(@group), notice: message
  end

  private

  def check_enabled_extras!
    render_404 unless Gitlab::Auth::LDAP::Config.group_sync_enabled?
  end
end
