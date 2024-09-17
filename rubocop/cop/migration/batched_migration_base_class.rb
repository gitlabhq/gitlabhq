# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      class BatchedMigrationBaseClass < RuboCop::Cop::Base
        MSG = 'Batched background migration jobs should inherit from either ' \
          'Gitlab::BackgroundMigration::BatchedMigrationJob ' \
          'or one of its subclasses.'

        BASE_CLASSES = %i[
          BatchedMigrationJob
          BackfillDesiredShardingKeyJob
          BackfillDesiredShardingKeyPartitionJob
        ].to_set.freeze

        def_node_search :top_level_module?, <<~PATTERN
          (module (const nil? :Gitlab) (module (const nil? :BackgroundMigration) ...))
        PATTERN

        def_node_matcher :matching_parent_namespace?, <<~PATTERN
          {nil? (const (const {cbase nil?} :Gitlab) :BackgroundMigration)}
        PATTERN

        def_node_search :inherits_batched_migration_job?, <<~PATTERN
          (class _ (const #matching_parent_namespace? %BASE_CLASSES) ...)
        PATTERN

        def on_module(module_node)
          return unless top_level_module?(module_node)

          top_level_class_node = module_node.each_descendant(:class).first

          return if top_level_class_node.nil? || inherits_batched_migration_job?(top_level_class_node)

          add_offense(top_level_class_node)
        end
      end
    end
  end
end
