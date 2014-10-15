module API
  # groups API
  class Ldap < Grape::API
    before { authenticate! }

    resource :ldap do
      helpers do
        def get_group_list(provider, search)
          Gitlab::LDAP::Adapter.new(provider).groups("#{search}*", 20)
        end
      end

      # Get a LDAP groups list. Limit size to 20 of them.
      # Filter results by name using search param
      #
      # Example Request:
      #  GET /ldap/groups
      get 'groups' do
        provider = Gitlab::LDAP::Config.servers.first['provider_name']
        @groups = Gitlab::LDAP::Adapter.new(provider).groups("#{params[:search]}*", 20)
        present @groups, with: Entities::LdapGroup
      end

      # Get a LDAP groups list by the requested provider. Lited size to 20 of them.
      # Filter results by name using search param
      #
      # Example Request:
      #  GET /ldap/ldapmain/groups
      get ':provider/groups' do
        @groups = get_group_list(params[:provider], params[:search])

        # NOTE: this should be deprecated in favour of /ldap/PROVIDER_NAME/groups
        # for now we just select the first LDAP server
        present @groups, with: Entities::LdapGroup
      end
    end
  end
end
