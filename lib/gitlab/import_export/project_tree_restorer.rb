# frozen_string_literal: true

module Gitlab
  module ImportExport
    class ProjectTreeRestorer
      LARGE_PROJECT_FILE_SIZE_BYTES = 500.megabyte

      attr_reader :user
      attr_reader :shared
      attr_reader :project

      def initialize(user:, shared:, project:)
        @user = user
        @shared = shared
        @project = project
        @tree_loader = ProjectTreeLoader.new
      end

      def restore
        @tree_hash = read_tree_hash
        @project_members = @tree_hash.delete('project_members')

        RelationRenameService.rename(@tree_hash)

        if relation_tree_restorer.restore
          import_failure_service.with_retry(action: 'set_latest_merge_request_diff_ids!') do
            @project.merge_requests.set_latest_merge_request_diff_ids!
          end

          true
        else
          false
        end
      rescue => e
        @shared.error(e)
        false
      end

      private

      def large_project?(path)
        File.size(path) >= LARGE_PROJECT_FILE_SIZE_BYTES
      end

      def read_tree_hash
        path = File.join(@shared.export_path, 'project.json')
        dedup_entries = large_project?(path) &&
          Feature.enabled?(:dedup_project_import_metadata, project.group)

        @tree_loader.load(path, dedup_entries: dedup_entries)
      rescue => e
        Rails.logger.error("Import/Export error: #{e.message}") # rubocop:disable Gitlab/RailsLogger
        raise Gitlab::ImportExport::Error.new('Incorrect JSON format')
      end

      def relation_tree_restorer
        @relation_tree_restorer ||= RelationTreeRestorer.new(
          user: @user,
          shared: @shared,
          importable: @project,
          tree_hash: @tree_hash,
          object_builder: object_builder,
          members_mapper: members_mapper,
          relation_factory: relation_factory,
          reader: reader
        )
      end

      def members_mapper
        @members_mapper ||= Gitlab::ImportExport::MembersMapper.new(exported_members: @project_members,
                                                                    user: @user,
                                                                    importable: @project)
      end

      def object_builder
        Gitlab::ImportExport::GroupProjectObjectBuilder
      end

      def relation_factory
        Gitlab::ImportExport::ProjectRelationFactory
      end

      def reader
        @reader ||= Gitlab::ImportExport::Reader.new(shared: @shared)
      end

      def import_failure_service
        @import_failure_service ||= ImportFailureService.new(@project)
      end
    end
  end
end
