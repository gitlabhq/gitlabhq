class Groups::LdapGroupLinksController < Groups::ApplicationController
  before_action :group
  before_action :require_ldap_enabled
  before_action :authorize_admin_group!

  layout 'group_settings'

  def index
  end

  def create
    ldap_group_link = @group.ldap_group_links.build(ldap_group_link_params)
    if ldap_group_link.save
      if request.referer && request.referer.include?('admin')
        redirect_to [:admin, @group], notice: 'New LDAP link saved'
      else
        redirect_back_or_default(default: { action: 'index' }, options: { notice: 'New LDAP link saved' })
      end
    else
      redirect_back_or_default(
        default: { action: 'index' },
        options: { alert: "Could not create new LDAP link: #{ldap_group_link.errors.full_messages * ', '}" }
      )
    end
  end

  def destroy
    @group.ldap_group_links.where(id: params[:id]).destroy_all
    redirect_back_or_default(default: { action: 'index' }, options: { notice: 'LDAP link removed' })
  end

  private

  def ldap_group_link_params
    params.require(:ldap_group_link).permit(:cn, :group_access, :provider)
  end
end
