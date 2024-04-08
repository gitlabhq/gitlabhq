# frozen_string_literal: true

module BulkImports
  module Common
    module Pipelines
      class MembersPipeline
        include Pipeline

        GROUP_MEMBER_RELATIONS = %i[direct inherited shared_from_groups].freeze
        PROJECT_MEMBER_RELATIONS = %i[direct inherited invited_groups shared_into_ancestors].freeze

        transformer Common::Transformers::ProhibitedAttributesTransformer
        transformer Common::Transformers::MemberAttributesTransformer

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
          member = portable.members.new(data)
          member.importing = true # avoid sending new member notification to the invited user
          member.save!
        end

        private

        def graphql_extractor
          @graphql_extractor ||= BulkImports::Common::Extractors::GraphqlExtractor
            .new(query: BulkImports::Common::Graphql::GetMembersQuery)
        end

        def existing_user_membership(user_id)
          execute_finder.find_by_user_id(user_id)
        end

        def finder
          @finder ||= if context.entity.group?
                        ::GroupMembersFinder.new(portable, current_user)
                      else
                        ::MembersFinder.new(portable, current_user)
                      end
        end

        def execute_finder
          finder.execute(include_relations: finder_relations)
        end

        def finder_relations
          if context.entity.group?
            GROUP_MEMBER_RELATIONS
          else
            PROJECT_MEMBER_RELATIONS
          end
        end
      end
    end
  end
end
