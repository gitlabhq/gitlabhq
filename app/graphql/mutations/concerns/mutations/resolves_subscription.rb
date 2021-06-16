# frozen_string_literal: true

module Mutations
  module ResolvesSubscription
    extend ActiveSupport::Concern

    included do
      argument :subscribed_state,
               GraphQL::BOOLEAN_TYPE,
               required: true,
               description: 'The desired state of the subscription.'
    end

    def resolve(project_path:, iid:, subscribed_state:)
      resource = authorized_find!(project_path: project_path, iid: iid)
      project = resource.project

      resource.set_subscription(current_user, subscribed_state, project)

      {
        resource.class.name.underscore.to_sym => resource,
        errors: errors_on_object(resource)
      }
    end
  end
end
