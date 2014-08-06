module API
  # groups API
  class Ldap < Grape::API
    before { authenticate! }

    resource :ldap do
      # Get a LDAP groups list. Limit size to 20 of them.
      # Filter results by name using search param
      #
      # Example Request:
      #  GET /ldap/groups
      get 'groups' do
        @groups = Gitlab::LDAP::Adapter.new.groups("#{params[:search]}*", 20)
        present @groups, with: Entities::LdapGroup
      end
    end
  end
end
