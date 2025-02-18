# frozen_string_literal: true

module Mutations
  module WorkItems
    module LinkedItems
      class Base < BaseMutation
        # Limit maximum number of items that can be linked at a time to avoid overloading the DB
        MAX_WORK_ITEMS = 10

        argument :id, ::Types::GlobalIDType[::WorkItem],
          required: true, description: 'Global ID of the work item.'

        field :work_item, ::Types::WorkItemType,
          null: true, description: 'Updated work item.'

        field :message, GraphQL::Types::String,
          null: true, description: 'Linked items update result message.'

        authorize :read_work_item

        def ready?(**args)
          if args[:work_items_ids].size > MAX_WORK_ITEMS
            raise Gitlab::Graphql::Errors::ArgumentError,
              format(
                _('No more than %{max_work_items} work items can be modified at the same time.'),
                max_work_items: MAX_WORK_ITEMS
              )
          end

          super
        end

        def resolve(**args)
          work_item = authorized_find!(id: args.delete(:id))
          service_response = update_links(work_item, args)

          {
            work_item: work_item,
            errors: service_response[:status] == :error ? Array.wrap(service_response[:message]) : [],
            message: service_response[:status] == :success ? service_response[:message] : ''
          }
        end

        private

        def update_links(work_item, params)
          raise NotImplementedError, "#{self.class} does not implement #{__method__}"
        end
      end
    end
  end
end
