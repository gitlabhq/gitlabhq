module API
  module V3
    class Groups < Grape::API
      include PaginationParams

      before { authenticate! }

      helpers do
        params :statistics_params do
          optional :statistics, type: Boolean, default: false, desc: 'Include project statistics'
        end

        def present_groups(groups, options = {})
          options = options.reverse_merge(
            with: ::API::Entities::Group,
            current_user: current_user,
          )

          groups = groups.with_statistics if options[:statistics]
          present paginate(groups), options
        end
      end

      resource :groups do
        desc 'Get list of owned groups for authenticated user' do
          success ::API::Entities::Group
        end
        params do
          use :pagination
          use :statistics_params
        end
        get '/owned' do
          present_groups current_user.owned_groups, statistics: params[:statistics]
        end
      end
    end
  end
end
