# frozen_string_literal: true

module Gitlab
  module ImportExport
    class ProjectTreeRestorer
      attr_reader :user
      attr_reader :shared
      attr_reader :project

      def initialize(user:, shared:, project:)
        @path = File.join(shared.export_path, 'project.json')
        @user = user
        @shared = shared
        @project = project
      end

      def restore
        @tree_hash = read_tree_hash
        @project_members = @tree_hash.delete('project_members')

        RelationRenameService.rename(@tree_hash)

        if relation_tree_restorer.restore
          @project.merge_requests.set_latest_merge_request_diff_ids!

          true
        else
          false
        end
      rescue => e
        @shared.error(e)
        false
      end

      private

      def read_tree_hash
        json = IO.read(@path)
        ActiveSupport::JSON.decode(json)
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

      def relation_factory
        Gitlab::ImportExport::RelationFactory
      end

      def reader
        @reader ||= Gitlab::ImportExport::Reader.new(shared: @shared)
      end
    end
  end
end
