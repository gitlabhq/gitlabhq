class Groups::LdapGroupLinksController < ApplicationController
  before_action :group
  before_action :authorize_admin_group!

  layout 'group'

  def index
  end

  def create
    ldap_group_link = @group.ldap_group_links.build(ldap_group_link_params)
    if ldap_group_link.save
      if request.referer && request.referer.include?('admin')
        redirect_to [:admin, @group], notice: 'New LDAP link saved'
      else
        redirect_to :back, notice: 'New LDAP link saved'
      end
    else
      redirect_to :back, alert: "Could not create new LDAP link: #{ldap_group_link.error.full_messages * ', '}"
    end
  end

  def destroy
    @group.ldap_group_links.where(id: params[:id]).destroy_all
    redirect_to :back, notice: 'LDAP link removed'
  end

  private

  def group
    @group ||= Group.find_by(path: params[:group_id])
  end

  def authorize_admin_group!
    render_404 unless can?(current_user, :manage_group, group)
  end

  def ldap_group_link_params
    params.require(:ldap_group_link).permit(:cn, :group_access)
  end
end