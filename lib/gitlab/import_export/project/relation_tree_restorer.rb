# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class RelationTreeRestorer < ImportExport::Group::RelationTreeRestorer
        # Relations which cannot be saved at project level (and have a group assigned)
        GROUP_MODELS = [GroupLabel, Milestone, Epic].freeze

        def restore_single_relation(relation_key)
          bulk_insert_without_cache_or_touch do
            process_relation!(relation_key, relations[relation_key])
          end
        end

        def relation_factory_params(relation_key, relation_index, data_hash)
          super.merge({ import_source: ::Import::SOURCE_PROJECT_EXPORT_IMPORT })
        end

        private

        def relations
          relations = super
          relations.delete("vulnerabilities") if Feature.disabled?(:import_vulnerabilities, user)
          relations
        end

        def group_models
          GROUP_MODELS
        end

        def bulk_insert_enabled
          true
        end

        def modify_attributes
          @importable.reconcile_shared_runners_setting!
          @importable.drop_visibility_level!
        end

        def relation_invalid_for_importable?(relation_object)
          group_models.include?(relation_object.class) && relation_object.group_id
        end
      end
    end
  end
end

Gitlab::ImportExport::Project::RelationTreeRestorer.prepend_mod
