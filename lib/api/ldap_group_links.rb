module API
  # LDAP group links API
  class LdapGroupLinks < Grape::API
    before { authenticate! }

    resource :groups do
      
      # Add a linked LDAP group to group
      #
      # Parameters:
      #   id (required) - The ID of a group
      #   cn (required) - The CN of a LDAP group
      #   group_access (required) - Level of permissions for the linked LDAP group
      #   provider (required) - the LDAP provider for this LDAP group
      #
      # Example Request:
      #   POST /groups/:id/ldap_group_links
      post ":id/ldap_group_links" do
        group = find_group(params[:id])
        authorize! :admin_group, group
        required_attributes! [:cn, :group_access, :provider]
        unless validate_access_level?(params[:group_access])
          render_api_error!("Wrong group access level", 422)
        end
        
        attrs = attributes_for_keys [:cn, :group_access, :provider]
        
        ldap_group_link = group.ldap_group_links.new(attrs)
        if ldap_group_link.save
          present ldap_group_link, with: Entities::LdapGroupLink
        else
          render_api_error!(ldap_group_link.errors.full_messages.first, 409)
        end
      end
      
      # Remove a linked LDAP group from group
      #
      # Parameters:
      #   id (required) - The ID of a group
      #   cn (required) - The CN of a LDAP group
      #
      # Example Request:
      #   DELETE /groups/:id/ldap_group_links/:cn
      delete ":id/ldap_group_links/:cn" do
        group = find_group(params[:id])
        authorize! :admin_group, group
        
        ldap_group_link = group.ldap_group_links.find_by(cn: params[:cn])
        if ldap_group_link
          ldap_group_link.destroy
        else
          render_api_error!('Linked LDAP group not found', 404)
        end
      end

      # Remove a linked LDAP group from group for a specific LDAP provider
      #
      # Parameters:
      #   id (required) - The ID of a group
      #   provider (required) - A LDAP provider
      #   cn (required) - The CN of a LDAP group
      #
      # Example Request:
      #   DELETE /groups/:id/ldap_group_links/:provider/:cn
      delete ":id/ldap_group_links/:provider/:cn" do
        group = find_group(params[:id])
        authorize! :admin_group, group
        
        ldap_group_link = group.ldap_group_links.find_by(cn: params[:cn], provider: params[:provider])
        if ldap_group_link
          ldap_group_link.destroy
        else
          render_api_error!('Linked LDAP group not found', 404)
        end
      end
    end
  end
end
