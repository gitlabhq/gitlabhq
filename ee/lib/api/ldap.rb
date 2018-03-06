module API
  class Ldap < Grape::API
    before { authenticated_as_admin! }

    resource :ldap do
      helpers do
        def get_group_list(provider, search)
          search = Net::LDAP::Filter.escape(search)
          Gitlab::Auth::LDAP::Adapter.new(provider).groups("#{search}*", 20)
        end

        params :search_params do
          optional :search, type: String, default: '', desc: 'Search for a specific LDAP group'
        end
      end

      desc 'Get a LDAP groups list. Limit size to 20 of them.' do
        success EE::API::Entities::LdapGroup
      end
      params do
        use :search_params
      end
      get 'groups' do
        provider = Gitlab::Auth::LDAP::Config.available_servers.first['provider_name']
        groups = get_group_list(provider, params[:search])
        present groups, with: EE::API::Entities::LdapGroup
      end

      desc 'Get a LDAP groups list by the requested provider. Limit size to 20 of them.' do
        success EE::API::Entities::LdapGroup
      end
      params do
        use :search_params
      end
      get ':provider/groups' do
        groups = get_group_list(params[:provider], params[:search])
        present groups, with: EE::API::Entities::LdapGroup
      end
    end
  end
end
