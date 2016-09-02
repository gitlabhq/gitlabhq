module API
  # Users API
  class Users < Grape::API
    before { authenticate! }

    resource :users, requirements: { uid: /[0-9]*/, id: /[0-9]*/ } do
      # Get a users list
      #
      # Example Request:
      #  GET /users
      #  GET /users?search=Admin
      #  GET /users?username=root
      get do
        unless can?(current_user, :read_users_list, nil)
          render_api_error!("Not authorized.", 403)
        end

        if params[:username].present?
          @users = User.where(username: params[:username])
        else
          skip_ldap = params[:skip_ldap].present? && params[:skip_ldap] == 'true'
          @users = User.all
          @users = @users.active if params[:active].present?
          @users = @users.non_ldap if skip_ldap
          @users = @users.search(params[:search]) if params[:search].present?
          @users = paginate @users
        end

        if current_user.is_admin?
          present @users, with: Entities::UserFull
        else
          present @users, with: Entities::UserBasic
        end
      end

      # Get a single user
      #
      # Parameters:
      #   id (required) - The ID of a user
      # Example Request:
      #   GET /users/:id
      get ":id" do
        @user = User.find(params[:id])

        if current_user && current_user.is_admin?
          present @user, with: Entities::UserFull
        elsif can?(current_user, :read_user, @user)
          present @user, with: Entities::User
        else
          render_api_error!("User not found.", 404)
        end
      end

      # Create user. Available only for admin
      #
      # Parameters:
      #   email (required)                  - Email
      #   password (required)               - Password
      #   name (required)                   - Name
      #   username (required)               - Name
      #   skype                             - Skype ID
      #   linkedin                          - Linkedin
      #   twitter                           - Twitter account
      #   website_url                       - Website url
      #   projects_limit                    - Number of projects user can create
      #   extern_uid                        - External authentication provider UID
      #   provider                          - External provider
      #   bio                               - Bio
      #   location                          - Location of the user
      #   admin                             - User is admin - true or false (default)
      #   can_create_group                  - User can create groups - true or false
      #   confirm                           - Require user confirmation - true (default) or false
      #   external                          - Flags the user as external - true or false(default)
      # Example Request:
      #   POST /users
      post do
        authenticated_as_admin!
        required_attributes! [:email, :password, :name, :username]
        attrs = attributes_for_keys [:email, :name, :password, :skype, :linkedin, :twitter, :projects_limit, :username, :bio, :location, :can_create_group, :admin, :confirm, :external]
        admin = attrs.delete(:admin)
        confirm = !(attrs.delete(:confirm) =~ /(false|f|no|0)$/i)
        user = User.build_user(attrs)
        user.admin = admin unless admin.nil?
        user.skip_confirmation! unless confirm
        identity_attrs = attributes_for_keys [:provider, :extern_uid]

        if identity_attrs.any?
          user.identities.build(identity_attrs)
        end

        if user.save
          present user, with: Entities::UserFull
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

      # Update user. Available only for admin
      #
      # Parameters:
      #   email                             - Email
      #   name                              - Name
      #   password                          - Password
      #   skype                             - Skype ID
      #   linkedin                          - Linkedin
      #   twitter                           - Twitter account
      #   website_url                       - Website url
      #   projects_limit                    - Limit projects each user can create
      #   bio                               - Bio
      #   location                          - Location of the user
      #   admin                             - User is admin - true or false (default)
      #   can_create_group                  - User can create groups - true or false
      #   external                          - Flags the user as external - true or false(default)
      # Example Request:
      #   PUT /users/:id
      put ":id" do
        authenticated_as_admin!

        attrs = attributes_for_keys [:email, :name, :password, :skype, :linkedin, :twitter, :website_url, :projects_limit, :username, :bio, :location, :can_create_group, :admin, :external]
        user = User.find(params[:id])
        not_found!('User') unless user

        admin = attrs.delete(:admin)
        user.admin = admin unless admin.nil?

        conflict!('Email has already been taken') if attrs[:email] &&
            User.where(email: attrs[:email]).
                where.not(id: user.id).count > 0

        conflict!('Username has already been taken') if attrs[:username] &&
            User.where(username: attrs[:username]).
                where.not(id: user.id).count > 0

        identity_attrs = attributes_for_keys [:provider, :extern_uid]
        if identity_attrs.any?
          identity = user.identities.find_by(provider: identity_attrs[:provider])
          if identity
            identity.update_attributes(identity_attrs)
          else
            identity = user.identities.build(identity_attrs)
            identity.save
          end
        end

        if user.update_attributes(attrs)
          present user, with: Entities::UserFull
        else
          render_validation_error!(user)
        end
      end

      # Add ssh key to a specified user. Only available to admin users.
      #
      # Parameters:
      #   id (required) - The ID of a user
      #   key (required) - New SSH Key
      #   title (required) - New SSH Key's title
      # Example Request:
      #   POST /users/:id/keys
      post ":id/keys" do
        authenticated_as_admin!
        required_attributes! [:title, :key]

        user = User.find(params[:id])
        attrs = attributes_for_keys [:title, :key]
        key = user.keys.new attrs
        if key.save
          present key, with: Entities::SSHKey
        else
          render_validation_error!(key)
        end
      end

      # Get ssh keys of a specified user. Only available to admin users.
      #
      # Parameters:
      #   uid (required) - The ID of a user
      # Example Request:
      #   GET /users/:uid/keys
      get ':uid/keys' do
        authenticated_as_admin!
        user = User.find_by(id: params[:uid])
        not_found!('User') unless user

        present user.keys, with: Entities::SSHKey
      end

      # Delete existing ssh key of a specified user. Only available to admin
      # users.
      #
      # Parameters:
      #   uid (required) - The ID of a user
      #   id (required) - SSH Key ID
      # Example Request:
      #   DELETE /users/:uid/keys/:id
      delete ':uid/keys/:id' do
        authenticated_as_admin!
        user = User.find_by(id: params[:uid])
        not_found!('User') unless user

        begin
          key = user.keys.find params[:id]
          key.destroy
        rescue ActiveRecord::RecordNotFound
          not_found!('Key')
        end
      end

      # Add email to a specified user. Only available to admin users.
      #
      # Parameters:
      #   id (required) - The ID of a user
      #   email (required) - Email address
      # Example Request:
      #   POST /users/:id/emails
      post ":id/emails" do
        authenticated_as_admin!
        required_attributes! [:email]

        user = User.find(params[:id])
        attrs = attributes_for_keys [:email]
        email = user.emails.new attrs
        if email.save
          NotificationService.new.new_email(email)
          present email, with: Entities::Email
        else
          render_validation_error!(email)
        end
      end

      # Get emails of a specified user. Only available to admin users.
      #
      # Parameters:
      #   uid (required) - The ID of a user
      # Example Request:
      #   GET /users/:uid/emails
      get ':uid/emails' do
        authenticated_as_admin!
        user = User.find_by(id: params[:uid])
        not_found!('User') unless user

        present user.emails, with: Entities::Email
      end

      # Delete existing email of a specified user. Only available to admin
      # users.
      #
      # Parameters:
      #   uid (required) - The ID of a user
      #   id (required) - Email ID
      # Example Request:
      #   DELETE /users/:uid/emails/:id
      delete ':uid/emails/:id' do
        authenticated_as_admin!
        user = User.find_by(id: params[:uid])
        not_found!('User') unless user

        begin
          email = user.emails.find params[:id]
          email.destroy

          user.update_secondary_emails!
        rescue ActiveRecord::RecordNotFound
          not_found!('Email')
        end
      end

      # Delete user. Available only for admin
      #
      # Example Request:
      #   DELETE /users/:id
      delete ":id" do
        authenticated_as_admin!
        user = User.find_by(id: params[:id])

        if user
          DeleteUserService.new(current_user).execute(user)
        else
          not_found!('User')
        end
      end

      # Block user. Available only for admin
      #
      # Example Request:
      #   PUT /users/:id/block
      put ':id/block' do
        authenticated_as_admin!
        user = User.find_by(id: params[:id])

        if !user
          not_found!('User')
        elsif !user.ldap_blocked?
          user.block
        else
          forbidden!('LDAP blocked users cannot be modified by the API')
        end
      end

      # Unblock user. Available only for admin
      #
      # Example Request:
      #   PUT /users/:id/unblock
      put ':id/unblock' do
        authenticated_as_admin!
        user = User.find_by(id: params[:id])

        if !user
          not_found!('User')
        elsif user.ldap_blocked?
          forbidden!('LDAP blocked users cannot be unblocked by the API')
        else
          user.activate
        end
      end
    end

    resource :user do
      # Get currently authenticated user
      #
      # Example Request:
      #   GET /user
      get do
        present @current_user, with: Entities::UserFull
      end

      # Get currently authenticated user's keys
      #
      # Example Request:
      #   GET /user/keys
      get "keys" do
        present current_user.keys, with: Entities::SSHKey
      end

      # Get single key owned by currently authenticated user
      #
      # Example Request:
      #   GET /user/keys/:id
      get "keys/:id" do
        key = current_user.keys.find params[:id]
        present key, with: Entities::SSHKey
      end

      # Add new ssh key to currently authenticated user
      #
      # Parameters:
      #   key (required) - New SSH Key
      #   title (required) - New SSH Key's title
      # Example Request:
      #   POST /user/keys
      post "keys" do
        required_attributes! [:title, :key]

        attrs = attributes_for_keys [:title, :key]
        key = current_user.keys.new attrs
        if key.save
          present key, with: Entities::SSHKey
        else
          render_validation_error!(key)
        end
      end

      # Delete existing ssh key of currently authenticated user
      #
      # Parameters:
      #   id (required) - SSH Key ID
      # Example Request:
      #   DELETE /user/keys/:id
      delete "keys/:id" do
        begin
          key = current_user.keys.find params[:id]
          key.destroy
        rescue
        end
      end

      # Get currently authenticated user's emails
      #
      # Example Request:
      #   GET /user/emails
      get "emails" do
        present current_user.emails, with: Entities::Email
      end

      # Get single email owned by currently authenticated user
      #
      # Example Request:
      #   GET /user/emails/:id
      get "emails/:id" do
        email = current_user.emails.find params[:id]
        present email, with: Entities::Email
      end

      # Add new email to currently authenticated user
      #
      # Parameters:
      #   email (required) - Email address
      # Example Request:
      #   POST /user/emails
      post "emails" do
        required_attributes! [:email]

        attrs = attributes_for_keys [:email]
        email = current_user.emails.new attrs
        if email.save
          NotificationService.new.new_email(email)
          present email, with: Entities::Email
        else
          render_validation_error!(email)
        end
      end

      # Delete existing email of currently authenticated user
      #
      # Parameters:
      #   id (required) - EMail ID
      # Example Request:
      #   DELETE /user/emails/:id
      delete "emails/:id" do
        begin
          email = current_user.emails.find params[:id]
          email.destroy

          current_user.update_secondary_emails!
        rescue
        end
      end
    end
  end
end
