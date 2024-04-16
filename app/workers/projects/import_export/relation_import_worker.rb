# frozen_string_literal: true

module Projects
  module ImportExport
    class RelationImportWorker
      include ApplicationWorker

      sidekiq_options retry: 6

      idempotent!
      data_consistency :delayed
      deduplicate :until_executed
      feature_category :importers
      urgency :low
      worker_resource_boundary :memory

      attr_reader :tracker, :project, :current_user

      def perform(tracker_id, user_id)
        @current_user = User.find(user_id)
        @tracker = ::Projects::ImportExport::RelationImportTracker.find(tracker_id)
        @project = tracker.project

        return unless tracker.can_start?

        tracker.start!

        extract_import_file
        process_import

        tracker.finish!
      rescue StandardError => error
        failure_service = Gitlab::ImportExport::ImportFailureService.new(project)
        failure_service.log_import_failure(
          source: 'RelationImportWorker#perform',
          exception: error,
          relation_key: tracker.relation
        )

        tracker.fail_op!

        raise
      end

      private

      def extract_import_file
        Gitlab::ImportExport::FileImporter.import(
          importable: project,
          archive_file: project.import_export_upload.import_file.path,
          shared: shared_export_data
        )
      end

      def process_import
        tree_restorer = Gitlab::ImportExport::Project::RelationTreeRestorer.new(
          user: current_user,
          shared: shared_export_data,
          relation_reader: relation_reader,
          object_builder: Gitlab::ImportExport::Project::ObjectBuilder,
          members_mapper: members_mapper,
          relation_factory: Gitlab::ImportExport::Project::RelationFactory,
          reader: Gitlab::ImportExport::Reader.new(shared: shared_export_data),
          importable: project,
          importable_attributes: relation_reader.consume_attributes('project'),
          importable_path: 'project',
          skip_on_duplicate_iid: true
        )

        tree_restorer.restore_single_relation(tracker.relation)
      end

      def relation_reader
        @relation_reader ||= Gitlab::ImportExport::Json::NdjsonReader.new(
          File.join(shared_export_data.export_path, 'tree')
        )
      end

      def members_mapper
        project_members = relation_reader
                            .consume_relation('project', 'project_members', mark_as_consumed: false)
                            .map(&:first)

        Gitlab::ImportExport::MembersMapper.new(
          exported_members: project_members,
          user: current_user,
          importable: project
        )
      end

      def shared_export_data
        @shared ||= project.import_export_shared
      end
    end
  end
end
