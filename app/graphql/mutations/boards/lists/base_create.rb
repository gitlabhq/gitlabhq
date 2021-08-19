# frozen_string_literal: true

module Mutations
  module Boards
    module Lists
      class BaseCreate < BaseMutation
        argument :backlog, GraphQL::Types::Boolean,
                 required: false,
                 description: 'Create the backlog list.'

        argument :label_id, ::Types::GlobalIDType[::Label],
                 required: false,
                 description: 'Global ID of an existing label.'

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

          response = create_list(board, params)

          {
            list: response.success? ? response.payload[:list] : nil,
            errors: response.errors
          }
        end

        private

        def create_list(board, params)
          raise NotImplementedError
        end

        def create_list_params(args)
          params = args.slice(*mutually_exclusive_args).with_indifferent_access
          params[:label_id] &&= ::GitlabSchema.parse_gid(params[:label_id], expected_type: ::Label).model_id

          params
        end

        def mutually_exclusive_args
          [:backlog, :label_id]
        end
      end
    end
  end
end
