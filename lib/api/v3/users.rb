module API
  module V3
    class Users < Grape::API
      include PaginationParams

      before do
        allow_access_with_scope :read_user if request.get?
        authenticate!
      end

      resource :users, requirements: { uid: /[0-9]*/, id: /[0-9]*/ } do
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

          events = user.events.
            merge(ProjectsFinder.new.execute(current_user)).
            references(:project).
            with_associations.
            recent

          present paginate(events), with: ::API::V3::Entities::Event
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
      end
    end
  end
end
