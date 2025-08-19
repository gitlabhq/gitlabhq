# frozen_string_literal: true

module WorkItems
  module DataSync
    module Handlers
      class CopyDataHandler
        attr_reader :work_item, :target_namespace, :target_work_item_type, :current_user, :params, :create_params,
          :operation

        # rubocop:disable Layout/LineLength -- Keyword arguments are making the line a bit longer
        def initialize(work_item:, target_namespace:, target_work_item_type:, current_user: nil, params: {}, overwritten_params: {})
          @work_item = work_item
          @target_namespace = target_namespace
          @target_work_item_type = target_work_item_type
          @current_user = current_user
          @params = params
          @operation = params.delete(:operation)

          @create_params = {
            id: nil,
            iid: nil,
            created_at: work_item.created_at,
            updated_at: work_item.updated_at,
            updated_by_id: work_item.updated_by_id,
            state_id: work_item.state_id,
            closed_at: work_item.closed_at,
            closed_by_id: work_item.closed_by_id,
            duplicated_to_id: work_item.duplicated_to_id,
            moved_to_id: work_item.moved_to_id,
            promoted_to_epic_id: work_item.promoted_to_epic_id,
            upvotes_count: work_item.upvotes_count,
            blocking_issues_count: work_item.blocking_issues_count,
            work_item_type: target_work_item_type,
            project_id: project&.id,
            namespace_id: target_namespace.id,
            title: work_item.title,
            author_id: work_item.author_id,
            relative_position: relative_position,
            confidential: work_item.confidential,
            cached_markdown_version: work_item.cached_markdown_version,
            lock_version: work_item.lock_version,
            service_desk_reply_to: service_desk_reply_to,
            imported_from: :none
          }.merge(overwritten_params)
        end
        # rubocop:enable Layout/LineLength

        def execute
          # create the new work item
          ::WorkItems::DataSync::BaseCreateService.new(
            original_work_item: work_item,
            operation: operation,
            container: target_namespace,
            current_user: current_user,
            params: create_params.merge(params)
          ).execute(skip_system_notes: skip_system_notes?)
        end

        private

        def skip_system_notes?
          (operation == :clone && !!params[:clone_with_notes]) || operation == :move || operation == :promote
        end

        def relative_position
          return if work_item.namespace.root_ancestor.id != target_namespace.root_ancestor.id

          work_item.relative_position
        end

        def project
          target_namespace.project if target_namespace.is_a?(Namespaces::ProjectNamespace)
        end

        def service_desk_reply_to
          return unless target_namespace.respond_to?(:project) # only for ProjectNamespace

          ::ServiceDesk::Emails.new(target_namespace.project).alias_address
        end
      end
    end
  end
end

WorkItems::DataSync::Handlers::CopyDataHandler.prepend_mod
