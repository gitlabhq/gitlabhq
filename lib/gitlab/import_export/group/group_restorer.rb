# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Group
      class GroupRestorer
        def initialize(
          user:,
          shared:,
          group:,
          attributes:,
          importable_path:,
          relation_reader:,
          reader:
        )
          @user = user
          @shared = shared
          @group = group
          @group_attributes = attributes
          @importable_path = importable_path
          @relation_reader = relation_reader
          @reader = reader
        end

        def restore
          # consume_relation returns a list of [relation, index]
          @group_members = @relation_reader
            .consume_relation(@importable_path, 'members')
            .map(&:first)

          return unless members_mapper.map

          restorer.restore
        end

        private

        def restorer
          @relation_tree_restorer ||= RelationTreeRestorer.new(
            user: @user,
            shared: @shared,
            relation_reader: @relation_reader,
            members_mapper: members_mapper,
            object_builder: object_builder,
            relation_factory: relation_factory,
            reader: @reader,
            importable: @group,
            importable_attributes: @group_attributes,
            importable_path: @importable_path
          )
        end

        def members_mapper
          @members_mapper ||= Gitlab::ImportExport::MembersMapper.new(
            exported_members: @group_members,
            user: @user,
            importable: @group
          )
        end

        def relation_factory
          Gitlab::ImportExport::Group::RelationFactory
        end

        def object_builder
          Gitlab::ImportExport::Group::ObjectBuilder
        end
      end
    end
  end
end
