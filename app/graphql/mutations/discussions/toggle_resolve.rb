# frozen_string_literal: true

module Mutations
  module Discussions
    class ToggleResolve < BaseMutation
      graphql_name 'DiscussionToggleResolve'

      description 'Toggles the resolved state of a discussion'

      argument :id,
                Types::GlobalIDType[Discussion],
                required: true,
                description: 'The global ID of the discussion.'

      argument :resolve,
               GraphQL::Types::Boolean,
               required: true,
               description: 'Will resolve the discussion when true, and unresolve the discussion when false.'

      field :discussion,
            Types::Notes::DiscussionType,
            null: true,
            description: 'The discussion after mutation.'

      def resolve(id:, resolve:)
        discussion = authorized_find_discussion!(id: id)
        errors = []

        begin
          if resolve
            resolve!(discussion)
          else
            unresolve!(discussion)
          end
        rescue ActiveRecord::RecordNotSaved
          errors << "Discussion failed to be #{'un' unless resolve}resolved"
        end

        {
          discussion: discussion,
          errors: errors
        }
      end

      private

      # `Discussion` permissions are checked through `Discussion#can_resolve?`,
      # so we use this method of checking permissions rather than by defining
      # an `authorize` permission and calling `authorized_find!`.
      def authorized_find_discussion!(id:)
        find_object(id: id).tap do |discussion|
          raise_resource_not_available_error! unless discussion&.can_resolve?(current_user)
        end
      end

      def find_object(id:)
        # TODO: remove explicit coercion once compatibility layer has been removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = Types::GlobalIDType[Discussion].coerce_isolated_input(id)
        GitlabSchema.find_by_gid(id)
      end

      def resolve!(discussion)
        ::Discussions::ResolveService.new(
          discussion.project,
          current_user,
          one_or_more_discussions: discussion
        ).execute
      end

      def unresolve!(discussion)
        ::Discussions::UnresolveService.new(discussion, current_user).execute
      end
    end
  end
end
