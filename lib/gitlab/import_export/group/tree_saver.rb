# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Group
      class TreeSaver
        attr_reader :full_path, :shared

        def initialize(group:, current_user:, shared:, params: {})
          @params = params
          @current_user = current_user
          @shared = shared
          @group = group
          @full_path = File.join(@shared.export_path, 'tree')
        end

        def save
          all_groups = Enumerator.new do |group_ids|
            groups.each do |group|
              serialize(group)
              group_ids << group.id
            end
          end

          json_writer.write_relation_array('groups', '_all', all_groups)

          true
        rescue StandardError => e
          @shared.error(e)
          false
        ensure
          json_writer&.close
        end

        private

        def groups
          @groups ||= Gitlab::ObjectHierarchy
            .new(::Group.where(id: @group.id))
            .base_and_descendants(with_depth: true)
            .order_by(:depth)
        end

        def serialize(group)
          ImportExport::Json::StreamingSerializer.new(
            group,
            group_tree,
            json_writer,
            exportable_path: "groups/#{group.id}"
          ).execute
        end

        def group_tree
          @group_tree ||= Gitlab::ImportExport::Reader.new(
            shared: @shared,
            config: group_config
          ).group_tree
        end

        def group_config
          Gitlab::ImportExport::Config.new(
            config: Gitlab::ImportExport.group_config_file
          ).to_h
        end

        def json_writer
          @json_writer ||= ImportExport::Json::NdjsonWriter.new(@full_path)
        end
      end
    end
  end
end
