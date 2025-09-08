# frozen_string_literal: true

module BulkImports
  module Common
    module Pipelines
      class MembersPipeline
        include Pipeline
        include HexdigestCacheStrategy
        include ::Gitlab::Utils::StrongMemoize

        GROUP_MEMBER_RELATIONS = %i[direct inherited shared_from_groups].freeze
        PROJECT_MEMBER_RELATIONS = %i[direct inherited invited_groups shared_into_ancestors].freeze

        transformer Common::Transformers::ProhibitedAttributesTransformer
        # The transformer is skipped when bulk_import_importer_user_mapping is enabled
        transformer Common::Transformers::MemberAttributesTransformer
        # The transformer is skipped when bulk_import_importer_user_mapping is disabled
        transformer Import::BulkImports::Common::Transformers::SourceUserMemberAttributesTransformer

        def extract(context)
          extracted_data = graphql_extractor.extract(context)

          # add source_xid to each entry to ensure uniqueness when caching
          extracted_data.each do |entry|
            entry['source_xid'] = context.source_xid
            entry['entity_type'] = context.entity_type
          end

          extracted_data
        end

        def load(_context, data)
          return unless data
          return unless can_create_members?

          # Remove source_xid and entity_type since we don't use them in membership creation
          data.delete('source_xid')
          data.delete('entity_type')

          if data[:source_user]
            create_placeholder_membership(data)
          else
            create_member(data)
          end
        end

        private

        def can_create_members?
          ::Import::MemberLimitCheckService.new(portable).execute.success?
        end
        strong_memoize_attr :can_create_members?

        def create_member(data)
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

        def create_placeholder_membership(data)
          result = Import::PlaceholderMemberships::CreateService.new(**data, ignore_duplicate_errors: true).execute

          return unless result.error?

          result.track_and_raise_exception(access_level: data[:access_level])
        end

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
