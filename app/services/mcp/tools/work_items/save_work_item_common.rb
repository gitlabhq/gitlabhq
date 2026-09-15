# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      module SaveWorkItemCommon
        private

        def ensure_single_parent_identifier!
          given = [:url, :project_id, :group_id].select { |key| params[key].present? }
          return if given.length <= 1

          raise ArgumentError, "Provide exactly one of url, project_id, or group_id (got #{given.join(', ')})"
        end

        def normalize_gid(value, model)
          value.to_s.start_with?('gid://') ? value.to_s : "gid://gitlab/#{model}/#{value}"
        end

        def normalize_gids(values, model)
          Array(values).map { |value| normalize_gid(value, model) }
        end

        def combined_label_gids(ids_key, names_key)
          return unless params.key?(ids_key) || params.key?(names_key)

          (normalize_gids(params[ids_key], 'Label') + resolve_label_gids(params[names_key])).uniq
        end

        def resolve_label_gids(names)
          # create_issue trims label names (comma-string input), so array input must too.
          names = Array(names).map { |name| name.to_s.strip }
          return [] if names.empty?

          parent = resolve_parent[:record]
          found = ::Labels::AvailableLabelsService
            .new(current_user, parent, { labels: names.dup })
            .find_or_create_by_titles(find_only: true)

          missing = names - found.map(&:title)
          if missing.any?
            raise ArgumentError, "Labels not found in #{parent.full_path} or its ancestor groups: #{missing.join(', ')}"
          end

          # Base-class GIDs so the same label given by id and by name dedups.
          found.map { |label| normalize_gid(label.id, 'Label') }
        end

        def milestone_widget
          return unless params.key?(:milestone_id) || params.key?(:milestone)

          { milestoneId: resolve_milestone_gid }
        end

        # milestone_id wins over the title so the unambiguous form cannot be
        # overridden by a stale or duplicated title.
        def resolve_milestone_gid
          parent = resolve_parent[:record]
          return validated_milestone_id_gid(parent) if params[:milestone_id].present?

          milestone = ::Issuables::MilestoneTitleResolverService
            .new(container: parent, title: params[:milestone].to_s)
            .execute

          unless milestone
            raise ArgumentError,
              "Milestone '#{params[:milestone]}' not found in #{parent.full_path} or its ancestor groups"
          end

          normalize_gid(milestone.id, 'Milestone')
        end

        # Issuable::Callbacks::Milestone silently drops out-of-scope milestones,
        # so an unvalidated id would read as success with no milestone set.
        def validated_milestone_id_gid(parent)
          raw = params[:milestone_id].to_s
          id = raw.start_with?('gid://') ? GlobalID.parse(raw)&.model_id : raw

          finder_params = case parent
                          when Group
                            { group_ids: parent.self_and_ancestors.select(:id) }
                          else
                            { project_ids: [parent.id], group_ids: parent.group&.self_and_ancestors&.select(:id) }
                          end

          milestone = MilestonesFinder.new(finder_params.merge(ids: [id])).execute.first
          unless milestone
            raise ArgumentError,
              "Milestone with id #{id} not found in #{parent.full_path} or its ancestor groups"
          end

          normalize_gid(milestone.id, 'Milestone')
        end

        def description_widget
          return unless params.key?(:description)

          validate_no_quick_actions!(params[:description], field_name: 'description')

          { description: params[:description] }
        end

        def assignees_widget
          return unless params.key?(:assignee_ids)

          { assigneeIds: normalize_gids(params[:assignee_ids], 'User') }
        end

        def start_and_due_date_widget
          {
            startDate: params[:start_date],
            dueDate: params[:due_date],
            isFixed: params[:is_fixed]
          }.compact.presence
        end

        def hierarchy_widget
          return unless params.key?(:parent_id)

          { parentId: normalize_gid(params[:parent_id], 'WorkItem') }
        end

        def health_status_widget
          return unless params.key?(:health_status)

          { healthStatus: params[:health_status] }
        end

        def status_widget
          return unless params.key?(:status_id)

          { status: params[:status_id] }
        end

        def agent_plan_widget
          {
            content: params[:agent_plan],
            readinessScore: params[:readiness_score]
          }.compact.presence
        end

        def process_result(result)
          processed = super
          return processed if processed[:isError]

          work_item = processed[:structuredContent]['workItem']
          return ::Mcp::Tools::Base::Response.error('Operation returned no data') unless work_item

          formatted = format_work_item(work_item)
          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(formatted) }]

          ::Mcp::Tools::Base::Response.success(formatted_content, formatted)
        end

        def format_work_item(work_item)
          {
            'id' => work_item['id'],
            'iid' => work_item['iid'],
            'type' => work_item.dig('workItemType', 'name'),
            'title' => work_item['title'],
            'state' => work_item['state'],
            'confidential' => work_item['confidential'],
            'web_url' => work_item['webUrl']
          }
        end
      end
    end
  end
end
