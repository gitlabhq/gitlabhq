# frozen_string_literal: true

module Types
  module MergeRequests
    class ParticipantType < ::Types::UserType
      graphql_name 'MergeRequestParticipant'
      description 'A user participating in a merge request.'

      include ::Types::MergeRequests::InteractsWithMergeRequest

      authorize :read_user
    end
  end
end
