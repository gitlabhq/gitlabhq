# frozen_string_literal: true

module Import
  module Offline
    module Exports
      class ProcessService
        include Gitlab::Utils::StrongMemoize

        PERFORM_DELAY = 5.seconds

        def initialize(offline_export)
          @offline_export = offline_export
        end

        def execute
          return unless offline_export
          return if offline_export.completed?
          return offline_export.fail_op! if all_relation_exports_failed?
          return offline_export.finish! if offline_export.started? && all_relation_exports_finished?

          process_offline_export
          re_enqueue
        end

        private

        attr_reader :offline_export

        def process_offline_export
          if offline_export.created?
            create_descendant_self_relations
            offline_export.start!
          end

          self_relation_exports.for_status(::BulkImports::Export::PENDING).each do |self_relation_export|
            response = ::BulkImports::ExportService.new(
              portable: self_relation_export.portable,
              user: offline_export.user,
              batched: true,
              offline_export_id: offline_export.id
            ).execute

            next if response.success?

            self_relation_export.update!(
              status_event: 'fail_op',
              error: response.message.truncate(255)
            )
          end
        end

        def create_descendant_self_relations
          # For each BulkImport::Export that has relation 'self', a group_id and belonging to the offline_export,
          # ensure each BulkImport::Export's group's descendant groups and projects also have a
          # BulkImport::Export record with relation: 'self' that belongs to the offline_export object
          self_relation_params = {
            offline_export_id: offline_export.id,
            user_id: offline_export.user_id,
            relation: ::BulkImports::FileTransfer::BaseConfig::SELF_RELATION,
            status: ::BulkImports::Export::PENDING
          }

          descendant_self_relations = []

          self_relation_exports.each do |self_relation_export|
            group = self_relation_export.group

            next unless group

            group.descendants.as_ids.each do |group_id|
              descendant_self_relations << self_relation_params.merge(group_id: group_id.id, project_id: nil)
            end

            group.all_projects.select(:id).each do |project|
              descendant_self_relations << self_relation_params.merge(group_id: nil, project_id: project.id)
            end
          end

          return if descendant_self_relations.empty?

          ::BulkImports::Export.insert_all(descendant_self_relations)
          clear_memoization(:self_relation_exports) # clear memoization to fetch new relation exports to process
        end

        def all_relation_exports_finished?
          relation_exports.all?(&:completed?)
        end

        def all_relation_exports_failed?
          relation_exports.all?(&:failed?)
        end

        def relation_exports
          offline_export.bulk_import_exports
        end
        strong_memoize_attr :relation_exports

        def self_relation_exports
          ::BulkImports::Export.for_offline_export_and_relation(
            offline_export, ::BulkImports::FileTransfer::BaseConfig::SELF_RELATION
          )
        end
        strong_memoize_attr :self_relation_exports

        def re_enqueue
          Import::Offline::ExportWorker.perform_in(PERFORM_DELAY, offline_export.id)
        end
      end
    end
  end
end
