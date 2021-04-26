# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Group
      class LegacyTreeSaver
        attr_reader :full_path, :shared

        def initialize(group:, current_user:, shared:, params: {})
          @params       = params
          @current_user = current_user
          @shared       = shared
          @group        = group
          @full_path    = File.join(@shared.export_path, ImportExport.group_filename)
        end

        def save
          group_tree = serialize(@group, reader.group_tree)
          tree_saver.save(group_tree, @shared.export_path, ImportExport.group_filename)

          true
        rescue StandardError => e
          @shared.error(e)
          false
        end

        private

        def serialize(group, relations_tree)
          group_tree = tree_saver.serialize(group, relations_tree)

          group.children.each do |child|
            group_tree['children'] ||= []
            group_tree['children'] << serialize(child, relations_tree)
          end

          group_tree
        rescue StandardError => e
          @shared.error(e)
        end

        def reader
          @reader ||= Gitlab::ImportExport::Reader.new(
            shared: @shared,
            config: Gitlab::ImportExport::Config.new(
              config: Gitlab::ImportExport.legacy_group_config_file
            ).to_h
          )
        end

        def tree_saver
          @tree_saver ||= LegacyRelationTreeSaver.new
        end
      end
    end
  end
end
