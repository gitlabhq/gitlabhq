module API
  class Users < Grape::API
    include PaginationParams
    include APIGuard
    include Helpers::CustomAttributes

    allow_access_with_scope :read_user, if: -> (request) { request.get? }

    resource :users, requirements: { uid: /[0-9]*/, id: /[0-9]*/ } do
      include CustomAttributesEndpoints

      before do
        authenticate_non_get!
      end

      helpers do
        def find_user_by_id(params)
          id = params[:user_id] || params[:id]
          User.find_by(id: id) || not_found!('User')
        end

        def reorder_users(users)
          if params[:order_by] && params[:sort]
            users.reorder(params[:order_by] => params[:sort])
          else
            users
          end
        end

        params :optional_attributes do
          optional :skype, type: String, desc: 'The Skype username'
          optional :linkedin, type: String, desc: 'The LinkedIn username'
          optional :twitter, type: String, desc: 'The Twitter username'
          optional :website_url, type: String, desc: 'The website of the user'
          optional :organization, type: String, desc: 'The organization of the user'
          optional :projects_limit, type: Integer, desc: 'The number of projects a user can create'
          optional :extern_uid, type: String, desc: 'The external authentication provider UID'
          optional :provider, type: String, desc: 'The external provider'
          optional :bio, type: String, desc: 'The biography of the user'
          optional :location, type: String, desc: 'The location of the user'
          optional :admin, type: Boolean, desc: 'Flag indicating the user is an administrator'
          optional :can_create_group, type: Boolean, desc: 'Flag indicating the user can create groups'
          optional :external, type: Boolean, desc: 'Flag indicating the user is an external user'
          optional :avatar, type: File, desc: 'Avatar image for user'
          all_or_none_of :extern_uid, :provider

          # EE
          optional :shared_runners_minutes_limit, type: Integer, desc: 'Pipeline minutes quota for this user'
        end

        params :sort_params do
          optional :order_by, type: String, values: %w[id name username created_at updated_at],
                              default: 'id', desc: 'Return users ordered by a field'
          optional :sort, type: String, values: %w[asc desc], default: 'desc',
                          desc: 'Return users sorted in ascending and descending order'
        end
      end

      desc 'Get the list of users' do
        success Entities::UserBasic
      end
      params do
        # CE
        optional :username, type: String, desc: 'Get a single user with a specific username'
        optional :extern_uid, type: String, desc: 'Get a single user with a specific external authentication provider UID'
        optional :provider, type: String, desc: 'The external provider'
        optional :search, type: String, desc: 'Search for a username'
        optional :active, type: Boolean, default: false, desc: 'Filters only active users'
        optional :external, type: Boolean, default: false, desc: 'Filters only external users'
        optional :blocked, type: Boolean, default: false, desc: 'Filters only blocked users'
        optional :created_after, type: DateTime, desc: 'Return users created after the specified time'
        optional :created_before, type: DateTime, desc: 'Return users created before the specified time'
        all_or_none_of :extern_uid, :provider

        use :sort_params
        use :pagination
        use :with_custom_attributes

        # EE
        optional :skip_ldap, type: Boolean, default: false, desc: 'Skip LDAP users'
      end
      get do
        authenticated_as_admin! if params[:external].present? || (params[:extern_uid].present? && params[:provider].present?)

        unless current_user&.admin?
          params.except!(:created_after, :created_before, :order_by, :sort, :two_factor)
        end

        users = UsersFinder.new(current_user, params).execute
        users = reorder_users(users)

        authorized = can?(current_user, :read_users_list)

        # When `current_user` is not present, require that the `username`
        # parameter is passed, to prevent an unauthenticated user from accessing
        # a list of all the users on the GitLab instance. `UsersFinder` performs
        # an exact match on the `username` parameter, so we are guaranteed to
        # get either 0 or 1 `users` here.
        authorized &&= params[:username].present? if current_user.blank?

        forbidden!("Not authorized to access /api/v4/users") unless authorized

        entity = current_user&.admin? ? Entities::UserWithAdmin : Entities::UserBasic
        users = users.preload(:identities, :u2f_registrations) if entity == Entities::UserWithAdmin
        users, options = with_custom_attributes(users, with: entity)

        present paginate(users), options
      end

      desc 'Get a single user' do
        success Entities::User
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'

        use :with_custom_attributes
      end
      get ":id" do
        user = User.find_by(id: params[:id])
        not_found!('User') unless user && can?(current_user, :read_user, user)

        opts = current_user&.admin? ? { with: Entities::UserWithAdmin } : { with: Entities::User }
        user, opts = with_custom_attributes(user, opts)

        present user, opts
      end

      desc 'Create a user. Available only for admins.' do
        success Entities::UserPublic
      end
      params do
        requires :email, type: String, desc: 'The email of the user'
        optional :password, type: String, desc: 'The password of the new user'
        optional :reset_password, type: Boolean, desc: 'Flag indicating the user will be sent a password reset token'
        optional :skip_confirmation, type: Boolean, desc: 'Flag indicating the account is confirmed'
        at_least_one_of :password, :reset_password
        requires :name, type: String, desc: 'The name of the user'
        requires :username, type: String, desc: 'The username of the user'
        use :optional_attributes
      end
      post do
        authenticated_as_admin!

        params = declared_params(include_missing: false)
        user = ::Users::CreateService.new(current_user, params).execute(skip_authorization: true)

        if user.persisted?
          present user, with: Entities::UserPublic
        else
          conflict!('Email has already been taken') if User
              .where(email: user.email)
              .count > 0

          conflict!('Username has already been taken') if User
              .where(username: user.username)
              .count > 0

          render_validation_error!(user)
        end
      end

      desc 'Update a user. Available only for admins.' do
        success Entities::UserPublic
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        optional :email, type: String, desc: 'The email of the user'
        optional :password, type: String, desc: 'The password of the new user'
        optional :skip_reconfirmation, type: Boolean, desc: 'Flag indicating the account skips the confirmation by email'
        optional :name, type: String, desc: 'The name of the user'
        optional :username, type: String, desc: 'The username of the user'
        use :optional_attributes
      end
      put ":id" do
        authenticated_as_admin!

        user = User.find_by(id: params.delete(:id))
        not_found!('User') unless user

        conflict!('Email has already been taken') if params[:email] &&
            User.where(email: params[:email])
                .where.not(id: user.id).count > 0

        conflict!('Username has already been taken') if params[:username] &&
            User.where(username: params[:username])
                .where.not(id: user.id).count > 0

        user_params = declared_params(include_missing: false)
        identity_attrs = user_params.slice(:provider, :extern_uid)

        if identity_attrs.any?
          identity = user.identities.find_by(provider: identity_attrs[:provider])

          if identity
            identity.update_attributes(identity_attrs)
          else
            identity = user.identities.build(identity_attrs)
            identity.save
          end
        end

        user_params[:password_expires_at] = Time.now if user_params[:password].present?

        result = ::Users::UpdateService.new(current_user, user_params.except(:extern_uid, :provider).merge(user: user)).execute

        if result[:status] == :success
          present user, with: Entities::UserPublic
        else
          render_validation_error!(user)
        end
      end

      desc 'Add an SSH key to a specified user. Available only for admins.' do
        success Entities::SSHKey
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        requires :key, type: String, desc: 'The new SSH key'
        requires :title, type: String, desc: 'The title of the new SSH key'
      end
      post ":id/keys" do
        authenticated_as_admin!

        user = User.find_by(id: params.delete(:id))
        not_found!('User') unless user

        key = user.keys.new(declared_params(include_missing: false))

        if key.save
          present key, with: Entities::SSHKey
        else
          render_validation_error!(key)
        end
      end

      desc 'Get the SSH keys of a specified user. Available only for admins.' do
        success Entities::SSHKey
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        use :pagination
      end
      get ':id/keys' do
        authenticated_as_admin!

        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        present paginate(user.keys), with: Entities::SSHKey
      end

      desc 'Delete an existing SSH key from a specified user. Available only for admins.' do
        success Entities::SSHKey
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        requires :key_id, type: Integer, desc: 'The ID of the SSH key'
      end
      delete ':id/keys/:key_id' do
        authenticated_as_admin!

        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        key = user.keys.find_by(id: params[:key_id])
        not_found!('Key') unless key

        destroy_conditionally!(key)
      end

      desc 'Add a GPG key to a specified user. Available only for admins.' do
        detail 'This feature was added in GitLab 10.0'
        success Entities::GPGKey
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        requires :key, type: String, desc: 'The new GPG key'
      end
      post ':id/gpg_keys' do
        authenticated_as_admin!

        user = User.find_by(id: params.delete(:id))
        not_found!('User') unless user

        key = user.gpg_keys.new(declared_params(include_missing: false))

        if key.save
          present key, with: Entities::GPGKey
        else
          render_validation_error!(key)
        end
      end

      desc 'Get the GPG keys of a specified user. Available only for admins.' do
        detail 'This feature was added in GitLab 10.0'
        success Entities::GPGKey
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        use :pagination
      end
      get ':id/gpg_keys' do
        authenticated_as_admin!

        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        present paginate(user.gpg_keys), with: Entities::GPGKey
      end

      desc 'Delete an existing GPG key from a specified user. Available only for admins.' do
        detail 'This feature was added in GitLab 10.0'
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        requires :key_id, type: Integer, desc: 'The ID of the GPG key'
      end
      delete ':id/gpg_keys/:key_id' do
        authenticated_as_admin!

        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        key = user.gpg_keys.find_by(id: params[:key_id])
        not_found!('GPG Key') unless key

        status 204
        key.destroy
      end

      desc 'Revokes an existing GPG key from a specified user. Available only for admins.' do
        detail 'This feature was added in GitLab 10.0'
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        requires :key_id, type: Integer, desc: 'The ID of the GPG key'
      end
      post ':id/gpg_keys/:key_id/revoke' do
        authenticated_as_admin!

        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        key = user.gpg_keys.find_by(id: params[:key_id])
        not_found!('GPG Key') unless key

        key.revoke
        status :accepted
      end

      desc 'Add an email address to a specified user. Available only for admins.' do
        success Entities::Email
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        requires :email, type: String, desc: 'The email of the user'
      end
      post ":id/emails" do
        authenticated_as_admin!

        user = User.find_by(id: params.delete(:id))
        not_found!('User') unless user

        email = Emails::CreateService.new(current_user, declared_params(include_missing: false).merge(user: user)).execute

        if email.errors.blank?
          present email, with: Entities::Email
        else
          render_validation_error!(email)
        end
      end

      desc 'Get the emails addresses of a specified user. Available only for admins.' do
        success Entities::Email
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        use :pagination
      end
      get ':id/emails' do
        authenticated_as_admin!
        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        present paginate(user.emails), with: Entities::Email
      end

      desc 'Delete an email address of a specified user. Available only for admins.' do
        success Entities::Email
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        requires :email_id, type: Integer, desc: 'The ID of the email'
      end
      delete ':id/emails/:email_id' do
        authenticated_as_admin!
        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        email = user.emails.find_by(id: params[:email_id])
        not_found!('Email') unless email

        destroy_conditionally!(email) do |email|
          Emails::DestroyService.new(current_user, user: user).execute(email)
        end
      end

      desc 'Delete a user. Available only for admins.' do
        success Entities::Email
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        optional :hard_delete, type: Boolean, desc: "Whether to remove a user's contributions"
      end
      delete ":id" do
        Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42279')

        authenticated_as_admin!

        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        destroy_conditionally!(user) do
          user.delete_async(deleted_by: current_user, params: params)
        end
      end

      desc 'Block a user. Available only for admins.'
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      post ':id/block' do
        authenticated_as_admin!
        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        if !user.ldap_blocked?
          user.block
        else
          forbidden!('LDAP blocked users cannot be modified by the API')
        end
      end

      desc 'Unblock a user. Available only for admins.'
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      post ':id/unblock' do
        authenticated_as_admin!
        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        if user.ldap_blocked?
          forbidden!('LDAP blocked users cannot be unblocked by the API')
        else
          user.activate
        end
      end

      params do
        requires :user_id, type: Integer, desc: 'The ID of the user'
      end
      segment ':user_id' do
        resource :impersonation_tokens do
          helpers do
            def finder(options = {})
              user = find_user_by_id(params)
              PersonalAccessTokensFinder.new({ user: user, impersonation: true }.merge(options))
            end

            def find_impersonation_token
              finder.find_by(id: declared_params[:impersonation_token_id]) || not_found!('Impersonation Token')
            end
          end

          before { authenticated_as_admin! }

          desc 'Retrieve impersonation tokens. Available only for admins.' do
            detail 'This feature was introduced in GitLab 9.0'
            success Entities::ImpersonationToken
          end
          params do
            use :pagination
            optional :state, type: String, default: 'all', values: %w[all active inactive], desc: 'Filters (all|active|inactive) impersonation_tokens'
          end
          get { present paginate(finder(declared_params(include_missing: false)).execute), with: Entities::ImpersonationToken }

          desc 'Create a impersonation token. Available only for admins.' do
            detail 'This feature was introduced in GitLab 9.0'
            success Entities::ImpersonationToken
          end
          params do
            requires :name, type: String, desc: 'The name of the impersonation token'
            optional :expires_at, type: Date, desc: 'The expiration date in the format YEAR-MONTH-DAY of the impersonation token'
            optional :scopes, type: Array, desc: 'The array of scopes of the impersonation token'
          end
          post do
            impersonation_token = finder.build(declared_params(include_missing: false))

            if impersonation_token.save
              present impersonation_token, with: Entities::ImpersonationToken
            else
              render_validation_error!(impersonation_token)
            end
          end

          desc 'Retrieve impersonation token. Available only for admins.' do
            detail 'This feature was introduced in GitLab 9.0'
            success Entities::ImpersonationToken
          end
          params do
            requires :impersonation_token_id, type: Integer, desc: 'The ID of the impersonation token'
          end
          get ':impersonation_token_id' do
            present find_impersonation_token, with: Entities::ImpersonationToken
          end

          desc 'Revoke a impersonation token. Available only for admins.' do
            detail 'This feature was introduced in GitLab 9.0'
          end
          params do
            requires :impersonation_token_id, type: Integer, desc: 'The ID of the impersonation token'
          end
          delete ':impersonation_token_id' do
            token = find_impersonation_token

            destroy_conditionally!(token) do
              token.revoke!
            end
          end
        end
      end
    end

    resource :user do
      before do
        authenticate!
      end

      desc 'Get the currently authenticated user' do
        success Entities::UserPublic
      end
      get do
        entity =
          if current_user.admin?
            Entities::UserWithAdmin
          else
            Entities::UserPublic
          end

        present current_user, with: entity
      end

      desc "Get the currently authenticated user's SSH keys" do
        success Entities::SSHKey
      end
      params do
        use :pagination
      end
      get "keys" do
        present paginate(current_user.keys), with: Entities::SSHKey
      end

      desc 'Get a single key owned by currently authenticated user' do
        success Entities::SSHKey
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the SSH key'
      end
      get "keys/:key_id" do
        key = current_user.keys.find_by(id: params[:key_id])
        not_found!('Key') unless key

        present key, with: Entities::SSHKey
      end

      desc 'Add a new SSH key to the currently authenticated user' do
        success Entities::SSHKey
      end
      params do
        requires :key, type: String, desc: 'The new SSH key'
        requires :title, type: String, desc: 'The title of the new SSH key'
      end
      post "keys" do
        key = current_user.keys.new(declared_params)

        if key.save
          present key, with: Entities::SSHKey
        else
          render_validation_error!(key)
        end
      end

      desc 'Delete an SSH key from the currently authenticated user' do
        success Entities::SSHKey
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the SSH key'
      end
      delete "keys/:key_id" do
        key = current_user.keys.find_by(id: params[:key_id])
        not_found!('Key') unless key

        destroy_conditionally!(key)
      end

      desc "Get the currently authenticated user's GPG keys" do
        detail 'This feature was added in GitLab 10.0'
        success Entities::GPGKey
      end
      params do
        use :pagination
      end
      get 'gpg_keys' do
        present paginate(current_user.gpg_keys), with: Entities::GPGKey
      end

      desc 'Get a single GPG key owned by currently authenticated user' do
        detail 'This feature was added in GitLab 10.0'
        success Entities::GPGKey
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the GPG key'
      end
      get 'gpg_keys/:key_id' do
        key = current_user.gpg_keys.find_by(id: params[:key_id])
        not_found!('GPG Key') unless key

        present key, with: Entities::GPGKey
      end

      desc 'Add a new GPG key to the currently authenticated user' do
        detail 'This feature was added in GitLab 10.0'
        success Entities::GPGKey
      end
      params do
        requires :key, type: String, desc: 'The new GPG key'
      end
      post 'gpg_keys' do
        key = current_user.gpg_keys.new(declared_params)

        if key.save
          present key, with: Entities::GPGKey
        else
          render_validation_error!(key)
        end
      end

      desc 'Revoke a GPG key owned by currently authenticated user' do
        detail 'This feature was added in GitLab 10.0'
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the GPG key'
      end
      post 'gpg_keys/:key_id/revoke' do
        key = current_user.gpg_keys.find_by(id: params[:key_id])
        not_found!('GPG Key') unless key

        key.revoke
        status :accepted
      end

      desc 'Delete a GPG key from the currently authenticated user' do
        detail 'This feature was added in GitLab 10.0'
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the SSH key'
      end
      delete 'gpg_keys/:key_id' do
        key = current_user.gpg_keys.find_by(id: params[:key_id])
        not_found!('GPG Key') unless key

        status 204
        key.destroy
      end

      desc "Get the currently authenticated user's email addresses" do
        success Entities::Email
      end
      params do
        use :pagination
      end
      get "emails" do
        present paginate(current_user.emails), with: Entities::Email
      end

      desc 'Get a single email address owned by the currently authenticated user' do
        success Entities::Email
      end
      params do
        requires :email_id, type: Integer, desc: 'The ID of the email'
      end
      get "emails/:email_id" do
        email = current_user.emails.find_by(id: params[:email_id])
        not_found!('Email') unless email

        present email, with: Entities::Email
      end

      desc 'Add new email address to the currently authenticated user' do
        success Entities::Email
      end
      params do
        requires :email, type: String, desc: 'The new email'
      end
      post "emails" do
        email = Emails::CreateService.new(current_user, declared_params.merge(user: current_user)).execute

        if email.errors.blank?
          present email, with: Entities::Email
        else
          render_validation_error!(email)
        end
      end

      desc 'Delete an email address from the currently authenticated user'
      params do
        requires :email_id, type: Integer, desc: 'The ID of the email'
      end
      delete "emails/:email_id" do
        email = current_user.emails.find_by(id: params[:email_id])
        not_found!('Email') unless email

        destroy_conditionally!(email) do |email|
          Emails::DestroyService.new(current_user, user: current_user).execute(email)
        end
      end

      desc 'Get a list of user activities'
      params do
        optional :from, type: DateTime, default: 6.months.ago, desc: 'Date string in the format YEAR-MONTH-DAY'
        use :pagination
      end
      get "activities" do
        authenticated_as_admin!

        activities = User
          .where(User.arel_table[:last_activity_on].gteq(params[:from]))
          .reorder(last_activity_on: :asc)

        present paginate(activities), with: Entities::UserActivity
      end
    end
  end
end
