# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Group
      class TreeRestorer
        include Gitlab::Utils::StrongMemoize

        attr_reader :user, :shared, :groups_mapping

        def initialize(user:, shared:, group:)
          @user = user
          @shared = shared
          @top_level_group = group
          @groups_mapping = {}
        end

        def restore
          group_ids = relation_reader.consume_relation('groups', '_all').map { |value, _idx| Integer(value) }
          root_group_id = group_ids.delete_at(0)

          process_root(root_group_id)

          group_ids.each do |group_id|
            process_child(group_id)
          end

          true
        rescue StandardError => e
          shared.error(e)
          false
        end

        class GroupAttributes
          attr_reader :attributes, :group_id, :id, :path

          def initialize(group_id, relation_reader)
            @group_id = group_id

            @path = "groups/#{group_id}"
            @attributes = relation_reader.consume_attributes(@path)
            @id = @attributes.delete('id')

            unless @id == @group_id
              raise ArgumentError, "Invalid group_id for #{group_id}"
            end
          end

          def delete_attribute(name)
            attributes.delete(name)
          end

          def delete_attributes(*names)
            names.map(&method(:delete_attribute))
          end
        end
        private_constant :GroupAttributes

        private

        def process_root(group_id)
          group_attributes = GroupAttributes.new(group_id, relation_reader)

          # name and path are not imported on the root group to avoid conflict
          # with existing groups name and/or path.
          group_attributes.delete_attributes('name', 'path')

          if @top_level_group.has_parent?
            group_attributes.attributes['visibility_level'] = sub_group_visibility_level(
              group_attributes.attributes['visibility_level'],
              @top_level_group.parent
            )
          elsif Gitlab::VisibilityLevel.restricted_level?(group_attributes.attributes['visibility_level'])
            group_attributes.delete_attribute('visibility_level')
          end

          restore_group(@top_level_group, group_attributes)
        end

        def process_child(group_id)
          group_attributes = GroupAttributes.new(group_id, relation_reader)

          group = create_group(group_attributes)

          restore_group(group, group_attributes)
        rescue StandardError => e
          import_failure_service.log_import_failure(
            source: 'process_child',
            relation_key: 'group',
            exception: e
          )
        end

        def create_group(group_attributes)
          parent_id = group_attributes.delete_attribute('parent_id')
          name = group_attributes.delete_attribute('name')
          path = group_attributes.delete_attribute('path')
          visibility_level = group_attributes.delete_attribute('visibility_level')

          parent_group = @groups_mapping.fetch(parent_id) { raise(ArgumentError, 'Parent group not found') }

          result = ::Groups::CreateService.new(
            user,
            name: name,
            path: path,
            parent_id: parent_group.id,
            visibility_level: sub_group_visibility_level(visibility_level, parent_group)
          ).execute
          group = result[:group]

          group.validate!

          group
        end

        def restore_group(group, group_attributes)
          @groups_mapping[group_attributes.id] = group

          Group::GroupRestorer.new(
            user: user,
            shared: shared,
            group: group,
            attributes: group_attributes.attributes,
            importable_path: group_attributes.path,
            relation_reader: relation_reader,
            reader: reader
          ).restore
        end

        def relation_reader
          strong_memoize(:relation_reader) do
            ImportExport::Json::NdjsonReader.new(
              File.join(shared.export_path, 'tree')
            )
          end
        end

        def sub_group_visibility_level(visibility_level, parent_group)
          parent_visibility_level = parent_group.visibility_level

          original_visibility_level = visibility_level ||
            closest_allowed_level(parent_visibility_level)

          if parent_visibility_level < original_visibility_level
            closest_allowed_level(parent_visibility_level)
          else
            closest_allowed_level(original_visibility_level)
          end
        end

        def closest_allowed_level(visibility_level)
          Gitlab::VisibilityLevel.closest_allowed_level(visibility_level)
        end

        def reader
          strong_memoize(:reader) do
            Gitlab::ImportExport::Reader.new(
              shared: @shared,
              config: Gitlab::ImportExport::Config.new(
                config: Gitlab::ImportExport.group_config_file
              ).to_h
            )
          end
        end

        def import_failure_service
          Gitlab::ImportExport::ImportFailureService.new(@top_level_group)
        end
      end
    end
  end
end
