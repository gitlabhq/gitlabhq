module API
  module V3
    class LdapGroupLinks < Grape::API
      before { authenticate! }

      params do
        requires :id, type: String, desc: 'The ID of a group'
      end
      resource :groups do
        desc 'Remove a linked LDAP group from group'
        params do
          requires 'cn', type: String, desc: 'The CN of a LDAP group'
        end
        delete ":id/ldap_group_links/:cn" do
          group = find_group(params[:id])
          authorize! :admin_group, group

          ldap_group_link = group.ldap_group_links.find_by(cn: params[:cn])
          if ldap_group_link
            status(200)
            ldap_group_link.destroy
          else
            render_api_error!('Linked LDAP group not found', 404)
          end
        end

        desc 'Remove a linked LDAP group from group'
        params do
          requires 'cn', type: String, desc: 'The CN of a LDAP group'
          requires 'provider', type: String, desc: 'The LDAP provider for this LDAP group'
        end
        delete ":id/ldap_group_links/:provider/:cn" do
          group = find_group(params[:id])
          authorize! :admin_group, group

          ldap_group_link = group.ldap_group_links.find_by(cn: params[:cn], provider: params[:provider])
          if ldap_group_link
            status(200)
            ldap_group_link.destroy
          else
            render_api_error!('Linked LDAP group not found', 404)
          end
        end
      end
    end
  end
end
