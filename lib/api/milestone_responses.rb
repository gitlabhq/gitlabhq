# frozen_string_literal: true

module API
  module MilestoneResponses
    extend ActiveSupport::Concern

    included do
      helpers do
        include ::API::Concerns::Milestones::GroupProjectParams

        params :optional_params do
          optional :description, type: String, desc: 'The description of the milestone'
          optional :due_date, type: String, desc: 'The due date of the milestone. The ISO 8601 date format (%Y-%m-%d)'
          optional :start_date, type: String, desc: 'The start date of the milestone. The ISO 8601 date format (%Y-%m-%d)'
        end

        params :list_params do
          optional :state, type: String, values: %w[active closed all], default: 'all',
            desc: 'Return "active", "closed", or "all" milestones'
          optional :iids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The IIDs of the milestones'
          optional :title, type: String, desc: 'The title of the milestones'
          optional :search, type: String, desc: 'The search criteria for the title or description of the milestone'
          optional :include_parent_milestones, type: Grape::API::Boolean, desc: 'Deprecated: see `include_ancestors`'
          optional :include_ancestors, type: Grape::API::Boolean, desc: 'Include milestones from all parent groups'
          optional :updated_before, type: DateTime, desc: 'Return milestones updated before the specified datetime. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ'
          optional :updated_after, type: DateTime, desc: 'Return milestones updated after the specified datetime. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ'
          mutually_exclusive :include_ancestors, :include_parent_milestones
          use :pagination
        end

        params :update_params do
          requires :milestone_id, type: Integer, desc: 'The milestone ID number'
          optional :title, type: String, desc: 'The title of the milestone'
          optional :state_event, type: String, values: %w[close activate],
            desc: 'The state event of the milestone '
          use :optional_params
          at_least_one_of :title, :description, :start_date, :due_date, :state_event
        end

        def list_milestones_for(parent)
          if params.include?(:include_parent_milestones)
            params[:include_ancestors] = params.delete(:include_parent_milestones)
          else
            # include_ancestors should default to false
            params[:include_ancestors] ||= false
          end

          milestones = MilestonesFinder.new(
            params.merge(parent_finder_params(parent))
          ).execute

          present paginate(milestones), with: Entities::Milestone
        end

        def get_milestone_for(parent)
          milestone = parent.milestones.find(params[:milestone_id])
          present milestone, with: Entities::Milestone
        end

        def create_milestone_for(parent)
          milestone = ::Milestones::CreateService.new(parent, current_user, declared_params).execute

          if milestone.valid?
            present milestone, with: Entities::Milestone
          else
            render_api_error!("Failed to create milestone #{milestone.errors.messages}", 400)
          end
        end

        def update_milestone_for(parent)
          milestone = parent.milestones.find(params.delete(:milestone_id))

          milestone_params = declared_params(include_missing: false)
          milestone = ::Milestones::UpdateService.new(parent, current_user, milestone_params).execute(milestone)

          if milestone.valid?
            present milestone, with: Entities::Milestone
          else
            render_api_error!("Failed to update milestone #{milestone.errors.messages}", 400)
          end
        end

        def milestone_issuables_for(parent, type)
          milestone = parent.milestones.find(params[:milestone_id])

          finder_klass, entity = get_finder_and_entity(type)

          params = build_finder_params(milestone, parent)

          issuables = finder_klass.new(current_user, params).execute.with_api_entity_associations
          present paginate(issuables), with: entity, current_user: current_user
        end

        def parent_finder_params(parent)
          if parent.is_a?(Project)
            project_finder_params(parent, params)
          else
            group_finder_params(parent, params)
          end
        end

        def build_finder_params(milestone, parent)
          finder_params = { milestone_title: milestone.title, sort: 'label_priority' }

          if parent.is_a?(Group)
            finder_params.merge(group_id: parent.id)
          else
            finder_params.merge(project_id: parent.id)
          end
        end

        def get_finder_and_entity(type)
          if type == :issue
            [IssuesFinder, Entities::IssueBasic]
          else
            [MergeRequestsFinder, Entities::MergeRequestBasic]
          end
        end
      end
    end
  end
end
