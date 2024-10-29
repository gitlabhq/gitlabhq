# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Aggregated
        class BaseQueryBuilder
          include StageQueryHelpers

          MODEL_CLASSES = {
            MergeRequest.to_s => ::Analytics::CycleAnalytics::MergeRequestStageEvent,
            Issue.to_s => ::Analytics::CycleAnalytics::IssueStageEvent
          }.freeze

          # Allowed params:
          # * from - stage end date filter start date
          # * to - stage end date filter to date
          # * author_username
          # * milestone_title
          # * label_name (array)
          # * assignee_username (array)
          # * project_ids (array)
          def initialize(stage:, params: {})
            @stage = stage
            @params = params
            @root_ancestor = stage.namespace.root_ancestor
            @stage_event_model = MODEL_CLASSES.fetch(stage.subject_class.to_s)
          end

          def build
            query = base_query
            query = filter_by_stage_parent(query)
            query = filter_author(query)
            query = filter_milestone_ids(query)
            query = filter_label_names(query)
            filter_assignees(query)
          end

          def build_sorted_query
            direction = params[:direction] || :desc

            if params[:sort] == :duration
              build.order_by_db_duration(direction)
            else
              build.order_by_end_event_with_db_duration(direction)
            end
          end

          def filter_author(query)
            return query if params[:author_username].blank?

            user = find_user(params[:author_username])
            return query.none if user.blank?

            query.authored(user)
          end

          def filter_milestone_ids(query)
            return query if params[:milestone_title].blank?

            milestone = find_milestone(params[:milestone_title])
            return query.none if milestone.blank?

            query.with_milestone_id(milestone.id)
          end

          def filter_label_names(query)
            return query if params[:label_name].blank?

            LabelFilter.new(
              stage: stage,
              params: params,
              project: nil,
              group: root_ancestor
            ).filter(query)
          end

          def filter_assignees(query)
            return query if params[:assignee_username].blank?

            Issuables::AssigneeFilter
              .new(params: { assignee_username: params[:assignee_username] })
              .filter(query)
          end

          def filter_by_stage_parent(query)
            query.by_project_id(stage.namespace.project.id)
          end

          def base_query
            query = stage_event_model
              .by_stage_event_hash_id(stage.stage_event_hash_id)

            from = params[:from] || 30.days.ago
            if in_progress?
              query = query
                .end_event_is_not_happened_yet
                .opened_state
                .start_event_timestamp_after(from)
              query = query.start_event_timestamp_before(params[:to]) if params[:to]
            else
              query = query.end_event_timestamp_after(from)
              query = query.end_event_timestamp_before(params[:to]) if params[:to]
            end

            query
          end

          private

          attr_reader :stage, :params, :root_ancestor, :stage_event_model

          def find_milestone(title)
            MilestonesFinder
              .new(group_ids: root_ancestor.self_and_descendant_ids, project_ids: root_ancestor.all_projects.select(:id), title: title)
              .execute
              .first
          end

          def find_user(username)
            User.by_username(username).first
          end
        end
      end
    end
  end
end
Gitlab::Analytics::CycleAnalytics::Aggregated::BaseQueryBuilder.prepend_mod_with('Gitlab::Analytics::CycleAnalytics::Aggregated::BaseQueryBuilder')
