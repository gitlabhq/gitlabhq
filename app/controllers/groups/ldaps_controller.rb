class Groups::LdapsController < Groups::ApplicationController
  before_action :group
  before_action :authorize_admin_group!

  def sync
    @group.pending_ldap_sync
    LdapGroupSyncWorker.perform_async(@group.id)

    redirect_to group_group_members_path(@group), notice: 'The group sync has been scheduled'
  end
end
