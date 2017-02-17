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
