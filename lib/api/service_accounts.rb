# frozen_string_literal: true

module API
  class ServiceAccounts < ::API::Base
    include PaginationParams

    before do
      authenticated_as_admin!
      set_current_organization
    end

    resource :service_accounts do
      desc 'Create a service account user. Available only for instance admins.' do
        tags ['service_accounts']
        success Entities::ServiceAccount
        failure [
          { code: 400, message: '400 Bad request' },
          { code: 401, message: '401 Unauthorized' },
          { code: 403, message: '403 Forbidden' }
        ]
      end

      params do
        optional :name, type: String, desc: 'Name of the user'
        optional :username, type: String, desc: 'Username of the user'
        optional :email, type: String, desc: 'Custom email address for the user'
      end

      route_setting :authorization, permissions: :create_service_account, boundary_type: :instance
      post feature_category: :user_management do
        check_rate_limit!(:service_account_creation, scope: current_user)

        response = ::Users::ServiceAccounts::CreateService.new(
          current_user, declared_params.merge(organization_id: Current.organization.id)
        ).execute

        if response.status == :success
          present response.payload[:user], with: Entities::ServiceAccount, current_user: current_user
        elsif response.reason == :forbidden
          forbidden!(response.message)
        else
          bad_request!(response.message)
        end
      end

      desc 'Get list of service account users. Available only for instance admins' do
        tags ['service_accounts']
        detail 'Get list of service account users'
        success Entities::ServiceAccount
        failure [
          { code: 400, message: '400 Bad request' },
          { code: 401, message: '401 Unauthorized' },
          { code: 403, message: '403 Forbidden' }
        ]
      end

      params do
        use :pagination
        optional :order_by, type: String, values: %w[id username], default: 'id',
          desc: 'Attribute to sort by'
        optional :sort, type: String, values: %w[asc desc], default: 'desc', desc: 'Order of sorting'
      end

      # rubocop: disable CodeReuse/ActiveRecord -- for the user or reorder
      route_setting :authorization, permissions: :read_service_account, boundary_type: :instance
      get do
        authorize! :admin_service_accounts

        users = User.service_account

        users = users.reorder(params[:order_by] => params[:sort])

        present paginate_with_strategies(users), with: Entities::ServiceAccount
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Update a service account user. Available only for instance admins.' do
        tags ['service_accounts']
        detail 'Update a service account user'
        success Entities::ServiceAccount
        failure [
          { code: 400, message: '400 Bad request' },
          { code: 401, message: '401 Unauthorized' },
          { code: 403, message: '403 Forbidden' },
          { code: 404, message: '404 Not found' }
        ]
      end

      params do
        requires :user_id, type: Integer, desc: 'The ID of the service account user'
        optional :name, type: String, desc: 'Name of the user'
        optional :username, type: String, desc: 'Username of the user'
        optional :email, type: String, desc: 'Custom email address for the user'
      end

      route_setting :authorization, permissions: :update_service_account, boundary_type: :instance
      patch ":user_id", feature_category: :user_management do
        authorize! :admin_service_accounts

        user = User.find(params[:user_id])
        update_params = declared_params(include_missing: false)

        response = ::Users::ServiceAccounts::UpdateService
                     .new(current_user, user, update_params)
                     .execute

        if response.status == :success
          present response.payload[:user], with: Entities::ServiceAccount, current_user: current_user
        else
          render_api_error!(response.message, response.reason)
        end
      end
    end
  end
end
