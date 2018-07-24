module EE
  module API
    module Namespaces
      extend ActiveSupport::Concern

      prepended do
        resource :namespaces do
          desc 'Update a namespace' do
            success Entities::Namespace
          end
          params do
            optional :plan, type: String, desc: "Namespace or Group plan"
            optional :shared_runners_minutes_limit, type: Integer, desc: "Pipeline minutes quota for this namespace"
            optional :trial_ends_on, type: Date, desc: "Trial expiration date"
          end
          put ':id' do
            authenticated_as_admin!

            namespace = find_namespace(params[:id])
            trial_ends_on = params[:trial_ends_on]

            break not_found!('Namespace') unless namespace
            break bad_request!("Invalid trial expiration date") if trial_ends_on&.past?

            if namespace.update(declared_params)
              present namespace, with: ::API::Entities::Namespace, current_user: current_user
            else
              render_validation_error!(namespace)
            end
          end
        end
      end
    end
  end
end
