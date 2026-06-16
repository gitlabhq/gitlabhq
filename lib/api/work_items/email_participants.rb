# frozen_string_literal: true

module API
  module WorkItems
    class EmailParticipants < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :service_desk
      urgency :low

      helpers ::API::Helpers::WorkItems::Preloads
      helpers ::API::Helpers::WorkItems::Rendering

      EMAIL_PARTICIPANT_DEFAULT_FIELDS = %i[id email].freeze

      EMAIL_PARTICIPANT_FIELD_LOOKUP = Entities::WorkItems::EmailParticipant
        .root_exposures
        .each_with_object({}) do |exposure, hash|
          key = exposure.key
          hash[key.to_s] = key
        end.freeze

      EMAIL_PARTICIPANT_SUPPORTED_FIELDS = EMAIL_PARTICIPANT_FIELD_LOOKUP.keys.freeze

      helpers do
        def render_email_participants_for(resource_parent, work_item_iid)
          check_work_item_rest_api_feature_flag!

          work_item = find_work_item_by_iid(resource_parent, work_item_iid)
          not_found!('Work Item') unless work_item

          authorize! :read_work_item, work_item

          widget = work_item.get_widget(:email_participants)
          not_found!('Email participants are not available for this work item type') unless widget

          participants = widget.email_participants.with_issue_and_project_ordered
          field_keys = filter_field_keys(params)

          present paginate(participants),
            with: Entities::WorkItems::EmailParticipant,
            current_user: current_user,
            fields: field_keys
        end

        def filter_field_keys(params)
          (EMAIL_PARTICIPANT_DEFAULT_FIELDS +
            filter_requested_keys(params[:fields], EMAIL_PARTICIPANT_FIELD_LOOKUP)).uniq
        end
      end

      resource :namespaces do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List email participants of a work item in a namespace.' do
            detail 'Get a paginated list of email participants for a work item in a namespace. ' \
              'Project and groups namespaces are supported.'
            hidden true
            success Entities::WorkItems::EmailParticipant
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
            optional :fields, type: String,
              desc: 'Comma-separated list of fields to include. ' \
                "Defaults to #{EMAIL_PARTICIPANT_DEFAULT_FIELDS.join(', ')}. " \
                "Supported values: #{EMAIL_PARTICIPANT_SUPPORTED_FIELDS.join(', ')}."
            use :pagination
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundaries: [{ boundary_type: :group }, { boundary_type: :project }],
            job_token_policies: :read_work_items
          get ':work_item_iid/email_participants' do
            namespace = find_namespace_by_path!(params[:id].to_s, allow_project_namespaces: true)
            not_found!('Namespace') if namespace.is_a?(::Namespaces::UserNamespace)
            resource_parent = namespace.is_a?(::Namespaces::ProjectNamespace) ? namespace.project : namespace

            render_email_participants_for(resource_parent, params[:work_item_iid])
          end
        end
      end

      resource :projects do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List email participants of a work item in a project.' do
            detail 'Get a paginated list of email participants for a work item in a project.'
            hidden true
            success Entities::WorkItems::EmailParticipant
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
            optional :fields, type: String,
              desc: 'Comma-separated list of fields to include. ' \
                "Defaults to #{EMAIL_PARTICIPANT_DEFAULT_FIELDS.join(', ')}. " \
                "Supported values: #{EMAIL_PARTICIPANT_SUPPORTED_FIELDS.join(', ')}."
            use :pagination
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :project,
            job_token_policies: :read_work_items
          get ':work_item_iid/email_participants' do
            project = find_project!(params[:id])

            render_email_participants_for(project, params[:work_item_iid])
          end
        end
      end

      resource :groups do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        end

        namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
          desc 'List email participants of a work item in a group.' do
            detail 'Get a paginated list of email participants for a work item in a group.'
            hidden true
            success Entities::WorkItems::EmailParticipant
            failure FAILURE_RESPONSES
            is_array true
            tags WORK_ITEMS_TAGS
          end
          params do
            requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
            optional :fields, type: String,
              desc: 'Comma-separated list of fields to include. ' \
                "Defaults to #{EMAIL_PARTICIPANT_DEFAULT_FIELDS.join(', ')}. " \
                "Supported values: #{EMAIL_PARTICIPANT_SUPPORTED_FIELDS.join(', ')}."
            use :pagination
          end
          route_setting :lifecycle, :experiment
          route_setting :authorization,
            permissions: :read_work_item,
            boundary_type: :group,
            job_token_policies: :read_work_items
          get ':work_item_iid/email_participants' do
            group = find_group!(params[:id])

            render_email_participants_for(group, params[:work_item_iid])
          end
        end
      end
    end
  end
end
