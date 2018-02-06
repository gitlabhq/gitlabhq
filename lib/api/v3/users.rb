module API
  module V3
    class Users < Grape::API
      include PaginationParams
      include APIGuard

      allow_access_with_scope :read_user, if: -> (request) { request.get? }

      before do
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
            optional :confirm, type: Boolean, default: true, desc: 'Flag indicating the account needs to be confirmed'
            optional :external, type: Boolean, desc: 'Flag indicating the user is an external user'
            all_or_none_of :extern_uid, :provider
          end
        end

        desc 'Create a user. Available only for admins.' do
          success ::API::Entities::UserPublic
        end
        params do
          requires :email, type: String, desc: 'The email of the user'
          optional :password, type: String, desc: 'The password of the new user'
          optional :reset_password, type: Boolean, desc: 'Flag indicating the user will be sent a password reset token'
          at_least_one_of :password, :reset_password
          requires :name, type: String, desc: 'The name of the user'
          requires :username, type: String, desc: 'The username of the user'
          use :optional_attributes
        end
        post do
          authenticated_as_admin!

          params = declared_params(include_missing: false)
          user = ::Users::CreateService.new(current_user, params.merge!(skip_confirmation: !params[:confirm])).execute

          if user.persisted?
            present user, with: ::API::Entities::UserPublic
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

        desc 'Get the SSH keys of a specified user. Available only for admins.' do
          success ::API::Entities::SSHKey
        end
        params do
          requires :id, type: Integer, desc: 'The ID of the user'
          use :pagination
        end
        get ':id/keys' do
          authenticated_as_admin!

          user = User.find_by(id: params[:id])
          not_found!('User') unless user

          present paginate(user.keys), with: ::API::Entities::SSHKey
        end

        desc 'Get the emails addresses of a specified user. Available only for admins.' do
          success ::API::Entities::Email
        end
        params do
          requires :id, type: Integer, desc: 'The ID of the user'
          use :pagination
        end
        get ':id/emails' do
          authenticated_as_admin!
          user = User.find_by(id: params[:id])
          not_found!('User') unless user

          present user.emails, with: ::API::Entities::Email
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
          success ::API::V3::Entities::Event
        end
        params do
          requires :id, type: Integer, desc: 'The ID of the user'
          use :pagination
        end
        get ':id/events' do
          user = User.find_by(id: params[:id])
          not_found!('User') unless user

          events = user.events
            .merge(ProjectsFinder.new(current_user: current_user).execute)
            .references(:project)
            .with_associations
            .recent

          present paginate(events), with: ::API::V3::Entities::Event
        end

        desc 'Delete an existing SSH key from a specified user. Available only for admins.' do
          success ::API::Entities::SSHKey
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

          present key.destroy, with: ::API::Entities::SSHKey
        end
      end

      resource :user do
        desc "Get the currently authenticated user's SSH keys" do
          success ::API::Entities::SSHKey
        end
        params do
          use :pagination
        end
        get "keys" do
          present current_user.keys, with: ::API::Entities::SSHKey
        end

        desc "Get the currently authenticated user's email addresses" do
          success ::API::Entities::Email
        end
        get "emails" do
          present current_user.emails, with: ::API::Entities::Email
        end

        desc 'Delete an SSH key from the currently authenticated user' do
          success ::API::Entities::SSHKey
        end
        params do
          requires :key_id, type: Integer, desc: 'The ID of the SSH key'
        end
        delete "keys/:key_id" do
          key = current_user.keys.find_by(id: params[:key_id])
          not_found!('Key') unless key

          present key.destroy, with: ::API::Entities::SSHKey
        end
      end
    end
  end
end
