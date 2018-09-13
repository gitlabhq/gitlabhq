module API
  class LdapGroupLinks < Grape::API
    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups do
      desc 'Add a linked LDAP group to group' do
        success EE::API::Entities::LdapGroupLink
      end
      params do
        requires 'cn', type: String, desc: 'The CN of a LDAP group'
        requires 'group_access', type: Integer, values: Gitlab::Access.all_values,
                                 desc: 'Level of permissions for the linked LDAP group'
        requires 'provider', type: String, desc: 'The LDAP provider for this LDAP group'
      end
      post ":id/ldap_group_links" do
        group = find_group(params[:id])
        authorize! :admin_group, group

        ldap_group_link = group.ldap_group_links.new(declared_params(include_missing: false))
        if ldap_group_link.save
          present ldap_group_link, with: EE::API::Entities::LdapGroupLink
        else
          render_api_error!(ldap_group_link.errors.full_messages.first, 409)
        end
      end

      desc 'Remove a linked LDAP group from group'
      params do
        requires 'cn', type: String, desc: 'The CN of a LDAP group'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id/ldap_group_links/:cn" do
        group = find_group(params[:id])
        authorize! :admin_group, group

        ldap_group_link = group.ldap_group_links.find_by(cn: params[:cn])
        if ldap_group_link
          ldap_group_link.destroy
          status 204
        else
          render_api_error!('Linked LDAP group not found', 404)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Remove a linked LDAP group from group'
      params do
        requires 'cn', type: String, desc: 'The CN of a LDAP group'
        requires 'provider', type: String, desc: 'The LDAP provider for this LDAP group'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id/ldap_group_links/:provider/:cn" do
        group = find_group(params[:id])
        authorize! :admin_group, group

        ldap_group_link = group.ldap_group_links.find_by(cn: params[:cn], provider: params[:provider])
        if ldap_group_link
          ldap_group_link.destroy
          status 204
        else
          render_api_error!('Linked LDAP group not found', 404)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
