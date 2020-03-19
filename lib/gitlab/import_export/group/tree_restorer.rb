# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Group
      class TreeRestorer
        attr_reader :user
        attr_reader :shared
        attr_reader :group

        def initialize(user:, shared:, group:, group_hash:)
          @path = File.join(shared.export_path, 'group.json')
          @user = user
          @shared = shared
          @group = group
          @group_hash = group_hash
        end

        def restore
          @relation_reader ||=
            if @group_hash.present?
              ImportExport::JSON::LegacyReader::User.new(@group_hash, reader.group_relation_names)
            else
              ImportExport::JSON::LegacyReader::File.new(@path, reader.group_relation_names)
            end

          @group_members = @relation_reader.consume_relation('members')
          @children = @relation_reader.consume_attribute('children')
          @relation_reader.consume_attribute('name')
          @relation_reader.consume_attribute('path')

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
        rescue => e
          @shared.error(e)
          false
        end

        private

        def restorer
          @relation_tree_restorer ||= RelationTreeRestorer.new(
            user:             @user,
            shared:           @shared,
            importable:       @group,
            relation_reader:  @relation_reader,
            members_mapper:   members_mapper,
            object_builder:   object_builder,
            relation_factory: relation_factory,
            reader:           reader
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
          @members_mapper ||= Gitlab::ImportExport::MembersMapper.new(exported_members: @group_members, user: @user, importable: @group)
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
              config: Gitlab::ImportExport.group_config_file
            ).to_h
          )
        end
      end
    end
  end
end
