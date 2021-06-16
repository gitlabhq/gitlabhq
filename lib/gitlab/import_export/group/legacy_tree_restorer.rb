# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Group
      class LegacyTreeRestorer
        include Gitlab::Utils::StrongMemoize

        attr_reader :user
        attr_reader :shared
        attr_reader :group

        def initialize(user:, shared:, group:, group_hash:)
          @user = user
          @shared = shared
          @group = group
          @group_hash = group_hash
        end

        def restore
          @group_attributes = relation_reader.consume_attributes(nil)
          @group_members = relation_reader.consume_relation(nil, 'members')
            .map(&:first)

          # We need to remove `name` and `path` as we did consume it in previous pass
          @group_attributes.delete('name')
          @group_attributes.delete('path')

          @children = @group_attributes.delete('children')

          if members_mapper.map && restorer.restore
            @children&.each do |group_hash|
              group = create_group(group_hash: group_hash, parent_group: @group)
              shared = Gitlab::ImportExport::Shared.new(group)

              self.class.new(
                user: @user,
                shared: shared,
                group: group,
                group_hash: group_hash
              ).restore
            end
          end

          return false if @shared.errors.any?

          true
        rescue StandardError => e
          @shared.error(e)
          false
        end

        private

        def relation_reader
          strong_memoize(:relation_reader) do
            if @group_hash.present?
              ImportExport::Json::LegacyReader::Hash.new(
                @group_hash,
                relation_names: reader.group_relation_names)
            else
              ImportExport::Json::LegacyReader::File.new(
                File.join(shared.export_path, 'group.json'),
                relation_names: reader.group_relation_names)
            end
          end
        end

        def restorer
          @relation_tree_restorer ||= RelationTreeRestorer.new(
            user:                  @user,
            shared:                @shared,
            relation_reader:       relation_reader,
            members_mapper:        members_mapper,
            object_builder:        object_builder,
            relation_factory:      relation_factory,
            reader:                reader,
            importable:            @group,
            importable_attributes: @group_attributes,
            importable_path:       nil
          )
        end

        def create_group(group_hash:, parent_group:)
          group_params = {
            name:      group_hash['name'],
            path:      group_hash['path'],
            parent_id: parent_group&.id,
            visibility_level: sub_group_visibility_level(group_hash, parent_group)
          }

          ::Groups::CreateService.new(@user, group_params).execute
        end

        def sub_group_visibility_level(group_hash, parent_group)
          original_visibility_level = group_hash['visibility_level'] || Gitlab::VisibilityLevel::PRIVATE

          if parent_group && parent_group.visibility_level < original_visibility_level
            Gitlab::VisibilityLevel.closest_allowed_level(parent_group.visibility_level)
          else
            original_visibility_level
          end
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

        def reader
          @reader ||= Gitlab::ImportExport::Reader.new(
            shared: @shared,
            config: Gitlab::ImportExport::Config.new(
              config: Gitlab::ImportExport.legacy_group_config_file
            ).to_h
          )
        end
      end
    end
  end
end
