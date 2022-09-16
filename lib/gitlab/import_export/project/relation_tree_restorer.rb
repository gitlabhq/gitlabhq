# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class RelationTreeRestorer < ImportExport::Group::RelationTreeRestorer
        # Relations which cannot be saved at project level (and have a group assigned)
        GROUP_MODELS = [GroupLabel, Milestone, Epic, Iteration].freeze

        private

        def bulk_insert_enabled
          true
        end

        def modify_attributes
          @importable.reconcile_shared_runners_setting!
          @importable.drop_visibility_level!
        end

        def relation_invalid_for_importable?(relation_object)
          GROUP_MODELS.include?(relation_object.class) && relation_object.group_id
        end
      end
    end
  end
end
