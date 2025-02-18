# frozen_string_literal: true

module Projects
  module ImportExport
    class RelationImportWorker
      include ApplicationWorker
      include Sidekiq::InterruptionsExhausted

      sidekiq_options retry: 6

      idempotent!
      data_consistency :delayed
      deduplicate :until_executed
      feature_category :importers
      urgency :low
      worker_resource_boundary :memory

      attr_reader :tracker, :project, :current_user

      sidekiq_retries_exhausted do |job, exception|
        new.perform_failure(job['args'].first, exception)
      end

      sidekiq_interruptions_exhausted do |job|
        new.perform_failure(job['args'].first,
          ::Import::Exceptions::SidekiqExhaustedInterruptionsError.new
        )
      end

      def perform(tracker_id, user_id)
        @current_user = User.find(user_id)
        @tracker = ::Projects::ImportExport::RelationImportTracker.find(tracker_id)
        @project = tracker.project

        unless tracker.can_start?
          ::Import::Framework::Logger.info(message: 'Cannot start tracker', tracker_id: tracker.id,
            tracker_status: tracker.status_name)
          return
        end

        tracker.start!

        extract_import_file
        process_import
        perform_post_import_tasks

        tracker.finish!
      rescue StandardError => error
        log_failure(error)

        raise
      ensure
        remove_extracted_import
      end

      def perform_failure(tracker_id, exception)
        @tracker = ::Projects::ImportExport::RelationImportTracker.find(tracker_id)
        @project = tracker.project

        log_failure(exception)
        tracker.fail_op!
      end

      private

      def extract_import_file
        Gitlab::ImportExport::FileImporter.import(
          importable: project,
          archive_file: nil,
          shared: project.import_export_shared,
          tmpdir: tmpdir,
          user: current_user
        )
      end

      def remove_extracted_import
        FileUtils.rm_rf(tmpdir)
      end

      def tmpdir
        @tmpdir ||= Dir.mktmpdir('export_archives')
      end

      def process_import
        tree_restorer = Gitlab::ImportExport::Project::RelationTreeRestorer.new(
          user: current_user,
          shared: project.import_export_shared,
          relation_reader: relation_reader,
          object_builder: Gitlab::ImportExport::Project::ObjectBuilder,
          members_mapper: members_mapper,
          relation_factory: Gitlab::ImportExport::Project::RelationFactory,
          reader: Gitlab::ImportExport::Reader.new(shared: project.import_export_shared),
          importable: project,
          importable_attributes: relation_reader.consume_attributes('project'),
          importable_path: 'project',
          skip_on_duplicate_iid: true
        )

        tree_restorer.restore_single_relation(tracker.relation)
      end

      def relation_reader
        @relation_reader ||= Gitlab::ImportExport::Json::NdjsonReader.new(
          File.join(tmpdir, 'tree')
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

      def perform_post_import_tasks
        project.reset_counters_and_iids
      end

      def log_failure(exception)
        failure_service = Gitlab::ImportExport::ImportFailureService.new(project)
        failure_service.log_import_failure(
          source: 'RelationImportWorker#perform',
          exception: exception,
          relation_key: tracker.relation
        )
      end
    end
  end
end
