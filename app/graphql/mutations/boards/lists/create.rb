# frozen_string_literal: true

module Mutations
  module Boards
    module Lists
      class Create < Base
        graphql_name 'BoardListCreate'

        argument :backlog, GraphQL::BOOLEAN_TYPE,
                 required: false,
                 description: 'Create the backlog list'

        argument :label_id, ::Types::GlobalIDType[::Label],
                 required: false,
                 description: 'Global ID of an existing label'

        def ready?(**args)
          if args.slice(*mutually_exclusive_args).size != 1
            arg_str = mutually_exclusive_args.map { |x| x.to_s.camelize(:lower) }.join(' or ')
            raise Gitlab::Graphql::Errors::ArgumentError, "one and only one of #{arg_str} is required"
          end

          super
        end

        def resolve(**args)
          board  = authorized_find!(id: args[:board_id])
          params = create_list_params(args)

          authorize_list_type_resource!(board, params)

          list = create_list(board, params)

          {
            list: list.valid? ? list : nil,
            errors: errors_on_object(list)
          }
        end

        private

        # Overridden in EE
        def authorize_list_type_resource!(board, params)
          return unless params[:label_id]

          labels = ::Labels::AvailableLabelsService.new(current_user, board.resource_parent, params)
            .filter_labels_ids_in_param(:label_id)

          unless labels.present?
            raise Gitlab::Graphql::Errors::ArgumentError, 'Label not found!'
          end
        end

        def create_list(board, params)
          create_list_service =
            ::Boards::Lists::CreateService.new(board.resource_parent, current_user, params)

          create_list_service.execute(board)
        end

        # Overridden in EE
        def create_list_params(args)
          params = args.slice(*mutually_exclusive_args).with_indifferent_access
          params[:label_id] &&= ::GitlabSchema.parse_gid(params[:label_id], expected_type: ::Label).model_id

          params
        end

        # Overridden in EE
        def mutually_exclusive_args
          [:backlog, :label_id]
        end
      end
    end
  end
end

Mutations::Boards::Lists::Create.prepend_if_ee('::EE::Mutations::Boards::Lists::Create')
