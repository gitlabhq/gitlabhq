# frozen_string_literal: true

module Types
  module Users
    class AutocompletedUserType < ::Types::UserType
      graphql_name 'AutocompletedUser'

      authorize :read_user

      field :merge_request_interaction, Types::UserMergeRequestInteractionType,
        null: true,
        description: 'Merge request state related to the user.' do
          argument :id, ::Types::GlobalIDType[::MergeRequest], required: true,
            description: 'Global ID of the merge request.'
        end

      def merge_request_interaction(id: nil)
        Gitlab::Graphql::Lazy.with_value(GitlabSchema.object_from_id(id, expected_class: ::MergeRequest)) do |mr|
          ::Users::MergeRequestInteraction.new(user: object.user, merge_request: mr) if mr
        end
      end
    end
  end
end
