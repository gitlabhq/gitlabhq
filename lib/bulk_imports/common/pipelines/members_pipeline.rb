# frozen_string_literal: true

module BulkImports
  module Common
    module Pipelines
      class MembersPipeline
        include Pipeline

        transformer Common::Transformers::ProhibitedAttributesTransformer
        transformer BulkImports::Groups::Transformers::MemberAttributesTransformer

        def extract(context)
          graphql_extractor.extract(context)
        end

        def load(_context, data)
          return unless data

          user_id = data[:user_id]

          # Current user is already a member
          return if user_id == current_user.id

          user_membership = existing_user_membership(user_id)

          # User is already a member with higher existing (inherited) membership
          return if user_membership && user_membership[:access_level] >= data[:access_level]

          # Create new membership for any other access level
          portable.members.create!(data)
        end

        private

        def graphql_extractor
          @graphql_extractor ||= BulkImports::Common::Extractors::GraphqlExtractor
            .new(query: BulkImports::Common::Graphql::GetMembersQuery)
        end

        def existing_user_membership(user_id)
          members_finder.execute.find_by_user_id(user_id)
        end

        def members_finder
          @members_finder ||= if context.entity.group?
                                ::GroupMembersFinder.new(portable, current_user)
                              else
                                ::MembersFinder.new(portable, current_user)
                              end
        end
      end
    end
  end
end
