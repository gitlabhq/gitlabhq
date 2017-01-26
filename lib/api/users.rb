module API
  class Users < Grape::API
    include PaginationParams

    before do
      allow_access_with_scope :read_user if request.get?
      authenticate!
    end

    resource :users, requirements: { uid: /[0-9]*/, id: /[0-9]*/ } do
      helpers do
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
          optional :confirm, type: Boolean, desc: 'Flag indicating the account needs to be confirmed'
          optional :external, type: Boolean, desc: 'Flag indicating the user is an external user'
          all_or_none_of :extern_uid, :provider
        end
      end

      desc 'Get the list of users' do
        success Entities::UserBasic
      end
      params do
        optional :username, type: String, desc: 'Get a single user with a specific username'
        optional :search, type: String, desc: 'Search for a username'
        optional :active, type: Boolean, default: false, desc: 'Filters only active users'
        optional :external, type: Boolean, default: false, desc: 'Filters only external users'
        optional :blocked, type: Boolean, default: false, desc: 'Filters only blocked users'
        use :pagination
      end
      get do
        unless can?(current_user, :read_users_list, nil)
          render_api_error!("Not authorized.", 403)
        end

        if params[:username].present?
          users = User.where(username: params[:username])
        else
          users = User.all
          users = users.active if params[:active]
          users = users.search(params[:search]) if params[:search].present?
          users = users.blocked if params[:blocked]
          users = users.external if params[:external] && current_user.is_admin?
        end

        entity = current_user.is_admin? ? Entities::UserPublic : Entities::UserBasic
        present paginate(users), with: entity
      end

      desc 'Get a single user' do
        success Entities::UserBasic
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      get ":id" do
        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        if current_user && current_user.is_admin?
          present user, with: Entities::UserPublic
        elsif can?(current_user, :read_user, user)
          present user, with: Entities::User
        else
          render_api_error!("User not found.", 404)
        end
      end

      desc 'Create a user. Available only for admins.' do
        success Entities::UserPublic
      end
      params do
        requires :email, type: String, desc: 'The email of the user'
        requires :password, type: String, desc: 'The password of the new user'
        requires :name, type: String, desc: 'The name of the user'
        requires :username, type: String, desc: 'The username of the user'
        use :optional_attributes
      end
      post do
        authenticated_as_admin!

        # Filter out params which are used later
        user_params = declared_params(include_missing: false)
        identity_attrs = user_params.slice(:provider, :extern_uid)
        confirm = user_params.delete(:confirm)

        user = User.new(user_params.except(:extern_uid, :provider))
        user.skip_confirmation! unless confirm

        if identity_attrs.any?
          user.identities.build(identity_attrs)
        end

        if user.save
          present user, with: Entities::UserPublic
        else
          conflict!('Email has already been taken') if User.
              where(email: user.email).
              count > 0

          conflict!('Username has already been taken') if User.
              where(username: user.username).
              count > 0

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
        optional :name, type: String, desc: 'The name of the user'
        optional :username, type: String, desc: 'The username of the user'
        use :optional_attributes
        at_least_one_of :email, :password, :name, :username, :skype, :linkedin,
                        :twitter, :website_url, :organization, :projects_limit,
                        :extern_uid, :provider, :bio, :location, :admin,
                        :can_create_group, :confirm, :external
      end
      put ":id" do
        authenticated_as_admin!

        user = User.find_by(id: params.delete(:id))
        not_found!('User') unless user

        conflict!('Email has already been taken') if params[:email] &&
            User.where(email: params[:email]).
                where.not(id: user.id).count > 0

        conflict!('Username has already been taken') if params[:username] &&
            User.where(username: params[:username]).
                where.not(id: user.id).count > 0

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

        if user.update_attributes(user_params.except(:extern_uid, :provider))
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
      end
      get ':id/keys' do
        authenticated_as_admin!

        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        present user.keys, with: Entities::SSHKey
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

        present key.destroy, with: Entities::SSHKey
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

        email = user.emails.new(declared_params(include_missing: false))

        if email.save
          NotificationService.new.new_email(email)
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
      end
      get ':id/emails' do
        authenticated_as_admin!
        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        present user.emails, with: Entities::Email
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

        email.destroy
        user.update_secondary_emails!
      end

      desc 'Delete a user. Available only for admins.' do
        success Entities::Email
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      delete ":id" do
        authenticated_as_admin!
        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        DeleteUserService.new(current_user).execute(user)
      end

      desc 'Block a user. Available only for admins.'
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
      end
      put ':id/block' do
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
      put ':id/unblock' do
        authenticated_as_admin!
        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        if user.ldap_blocked?
          forbidden!('LDAP blocked users cannot be unblocked by the API')
        else
          user.activate
        end
      end

      desc 'Get the contribution events of a specified user' do
        detail 'This feature was introduced in GitLab 8.13.'
        success Entities::Event
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the user'
        use :pagination
      end
      get ':id/events' do
        user = User.find_by(id: params[:id])
        not_found!('User') unless user

        events = user.events.
          merge(ProjectsFinder.new.execute(current_user)).
          references(:project).
          with_associations.
          recent

        present paginate(events), with: Entities::Event
      end
    end

    resource :user do
      desc 'Get the currently authenticated user' do
        success Entities::UserPublic
      end
      get do
        present current_user, with: sudo? ? Entities::UserWithPrivateToken : Entities::UserPublic
      end

      desc "Get the currently authenticated user's SSH keys" do
        success Entities::SSHKey
      end
      get "keys" do
        present current_user.keys, with: Entities::SSHKey
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

        present key.destroy, with: Entities::SSHKey
      end

      desc "Get the currently authenticated user's email addresses" do
        success Entities::Email
      end
      get "emails" do
        present current_user.emails, with: Entities::Email
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
        email = current_user.emails.new(declared_params)

        if email.save
          NotificationService.new.new_email(email)
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

        email.destroy
        current_user.update_secondary_emails!
      end
    end
  end
end
