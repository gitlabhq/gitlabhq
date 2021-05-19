# frozen_string_literal: true

module API
  module TimeTrackingEndpoints
    extend ActiveSupport::Concern

    included do
      helpers do
        def issuable_name
          declared_params.key?(:issue_iid) ? 'issue' : 'merge_request'
        end

        def issuable_key
          "#{issuable_name}_iid".to_sym
        end

        def admin_issuable_key
          "admin_#{issuable_name}".to_sym
        end

        def read_issuable_key
          "read_#{issuable_name}".to_sym
        end

        def load_issuable
          @issuable ||= begin
            case issuable_name
            when 'issue'
              find_project_issue(params.delete(issuable_key))
            when 'merge_request'
              find_project_merge_request(params.delete(issuable_key))
            end
          end
        end

        def update_issuable(attrs)
          custom_params = declared_params(include_missing: false)
          custom_params.merge!(attrs)

          issuable = update_service.new(project: user_project, current_user: current_user, params: custom_params).execute(load_issuable)
          if issuable.valid?
            present issuable, with: Entities::IssuableTimeStats
          else
            render_validation_error!(issuable)
          end
        end

        def update_service
          issuable_name == 'issue' ? ::Issues::UpdateService : ::MergeRequests::UpdateService
        end
      end

      issuable_name            = name.end_with?('Issues') ? 'issue' : 'merge_request'
      issuable_collection_name = issuable_name.pluralize
      issuable_key             = "#{issuable_name}_iid".to_sym

      desc "Set a time estimate for a project #{issuable_name}"
      params do
        requires issuable_key, type: Integer, desc: "The ID of a project #{issuable_name}"
        requires :duration, type: String, desc: 'The duration to be parsed'
      end
      post ":id/#{issuable_collection_name}/:#{issuable_key}/time_estimate" do
        authorize! admin_issuable_key, load_issuable

        status :ok
        update_issuable(time_estimate: Gitlab::TimeTrackingFormatter.parse(params.delete(:duration)))
      end

      desc "Reset the time estimate for a project #{issuable_name}"
      params do
        requires issuable_key, type: Integer, desc: "The ID of a project #{issuable_name}"
      end
      post ":id/#{issuable_collection_name}/:#{issuable_key}/reset_time_estimate" do
        authorize! admin_issuable_key, load_issuable

        status :ok
        update_issuable(time_estimate: 0)
      end

      desc "Add spent time for a project #{issuable_name}"
      params do
        requires issuable_key, type: Integer, desc: "The ID of a project #{issuable_name}"
        requires :duration, type: String, desc: 'The duration to be parsed'
      end
      post ":id/#{issuable_collection_name}/:#{issuable_key}/add_spent_time" do
        authorize! admin_issuable_key, load_issuable

        update_params = {
          spend_time: {
            duration: Gitlab::TimeTrackingFormatter.parse(params.delete(:duration)),
            user_id: current_user.id
          }
        }
        update_params[:use_specialized_service] = true if issuable_name == 'merge_request'

        update_issuable(update_params)
      end

      desc "Reset spent time for a project #{issuable_name}"
      params do
        requires issuable_key, type: Integer, desc: "The ID of a project #{issuable_name}"
      end
      post ":id/#{issuable_collection_name}/:#{issuable_key}/reset_spent_time" do
        authorize! admin_issuable_key, load_issuable

        status :ok
        update_issuable(spend_time: { duration: :reset, user_id: current_user.id })
      end

      desc "Show time stats for a project #{issuable_name}"
      params do
        requires issuable_key, type: Integer, desc: "The ID of a project #{issuable_name}"
      end
      get ":id/#{issuable_collection_name}/:#{issuable_key}/time_stats" do
        authorize! read_issuable_key, load_issuable

        present load_issuable, with: Entities::IssuableTimeStats
      end
    end
  end
end
