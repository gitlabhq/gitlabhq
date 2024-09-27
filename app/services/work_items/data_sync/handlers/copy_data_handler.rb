# frozen_string_literal: true

module WorkItems
  module DataSync
    module Handlers
      class CopyDataHandler
        attr_reader :work_item, :target_namespace, :target_work_item_type, :current_user, :params, :create_params

        # rubocop:disable Layout/LineLength -- Keyword arguments are making the line a bit longer
        def initialize(work_item:, target_namespace:, target_work_item_type:, current_user: nil, params: {}, overwritten_params: {})
          @work_item = work_item
          @target_namespace = target_namespace
          @target_work_item_type = target_work_item_type
          @current_user = current_user
          @params = params

          @create_params = {
            id: nil,
            iid: nil,
            title: work_item.title,
            work_item_type: target_work_item_type,
            relative_position: relative_position,
            author: work_item.author,
            project_id: project&.id,
            namespace_id: target_namespace.id,
            imported_from: :none
          }.merge(overwritten_params)
        end
        # rubocop:enable Layout/LineLength

        def execute
          # create the new work item
          ::WorkItems::DataSync::BaseCreateService.new(
            original_work_item: work_item,
            container: target_namespace,
            current_user: current_user,
            params: create_params
          ).execute(skip_system_notes: true)
        end

        private

        def relative_position
          return if work_item.namespace.root_ancestor.id != target_namespace.root_ancestor.id

          work_item.relative_position
        end

        def project
          target_namespace.project if target_namespace.is_a?(Namespaces::ProjectNamespace)
        end
      end
    end
  end
end
