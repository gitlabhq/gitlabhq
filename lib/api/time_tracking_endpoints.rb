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
          :"#{issuable_name}_iid"
        end

        def admin_issuable_key
          :"admin_#{issuable_name}"
        end

        def read_issuable_key
          :"read_#{issuable_name}"
        end

        def load_issuable
          @issuable ||= case issuable_name
                        when 'issue'
                          find_project_issue(params.delete(issuable_key))
                        when 'merge_request'
                          find_project_merge_request(params.delete(issuable_key))
                        end
        end

        def update_issuable(attrs)
          custom_params = declared_params(include_missing: false)
          custom_params.merge!(attrs)

          issuable = update_service.new(**update_service.constructor_container_arg(user_project),
            current_user: current_user, params: custom_params).execute(load_issuable)

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
      issuable_key             = :"#{issuable_name}_iid"
      issuable_human           = issuable_name.humanize(capitalize: false)
      issuable_article         = issuable_human.match?(/\A[aeiou]/i) ? 'an' : 'a'

      desc "Set the estimated time for #{issuable_article} #{issuable_human}" do
        detail "Sets an estimated time of work for a specified #{issuable_human}."
        success Entities::IssuableTimeStats
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' }
        ]
        tags [issuable_collection_name]
      end
      params do
        requires issuable_key, type: Integer, desc: "The internal ID of the #{issuable_name}."
        requires :duration, type: String, desc: 'The duration in human format.', documentation: { example: '3h30m' }
      end
      route_setting :authorization, permissions: :"create_#{issuable_name}_time_estimate", boundary_type: :project
      post ":id/#{issuable_collection_name}/:#{issuable_key}/time_estimate" do
        authorize! admin_issuable_key, load_issuable

        time_estimate = Gitlab::TimeTrackingFormatter.parse(params.delete(:duration), keep_zero: true)

        if time_estimate && time_estimate >= 0
          status :ok
          update_issuable(time_estimate: time_estimate)
        else
          bad_request!(reason: 'Time estimate must have a valid format and be greater than or equal to zero.')
        end
      end

      desc "Reset the estimated time for #{issuable_article} #{issuable_human}" do
        detail "Resets the estimated time for a specified #{issuable_human} to `0` seconds."
        success Entities::IssuableTimeStats
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags [issuable_collection_name]
      end
      params do
        requires issuable_key, type: Integer, desc: "The internal ID of the #{issuable_name}."
      end
      route_setting :authorization, permissions: :"reset_#{issuable_name}_time_estimate", boundary_type: :project
      post ":id/#{issuable_collection_name}/:#{issuable_key}/reset_time_estimate" do
        authorize! admin_issuable_key, load_issuable

        status :ok
        update_issuable(time_estimate: 0)
      end

      desc "Add spent time for #{issuable_article} #{issuable_human}" do
        detail "Adds spent time for a specified #{issuable_human}."
        success Entities::IssuableTimeStats
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags [issuable_collection_name]
      end
      params do
        requires issuable_key, type: Integer, desc: "The internal ID of the #{issuable_name}."
        requires :duration, type: String, desc: 'The duration in human format.'
      end
      route_setting :authorization, permissions: :"add_#{issuable_name}_spent_time", boundary_type: :project
      post ":id/#{issuable_collection_name}/:#{issuable_key}/add_spent_time" do
        authorize! admin_issuable_key, load_issuable

        update_params = {
          spend_time: {
            duration: Gitlab::TimeTrackingFormatter.parse(params.delete(:duration)),
            summary: params.delete(:summary),
            user_id: current_user.id
          }
        }
        update_params[:use_specialized_service] = true if issuable_name == 'merge_request'

        update_issuable(update_params)
      end

      desc "Reset spent time for #{issuable_article} #{issuable_human}" do
        detail "Resets the total spent time for a specified #{issuable_human} to `0` seconds."
        success Entities::IssuableTimeStats
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags [issuable_collection_name]
      end
      params do
        requires issuable_key, type: Integer, desc: "The internal ID of the #{issuable_name}"
      end
      route_setting :authorization, permissions: :"reset_#{issuable_name}_spent_time", boundary_type: :project
      post ":id/#{issuable_collection_name}/:#{issuable_key}/reset_spent_time" do
        authorize! admin_issuable_key, load_issuable

        status :ok
        update_issuable(spend_time: { duration: :reset, user_id: current_user.id })
      end

      desc "Retrieve time tracking stats for #{issuable_article} #{issuable_human}" do
        detail "Retrieves time tracking stats for a specified #{issuable_human}, including time estimate and time " \
          "spent in seconds and human-readable format (for example, `1h 30m`)."
        success Entities::IssuableTimeStats
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags [issuable_collection_name]
      end
      params do
        requires issuable_key, type: Integer, desc: "The internal ID of the #{issuable_name}"
      end
      route_setting :authorization, permissions: :"read_#{issuable_name}_time_statistic", boundary_type: :project
      get ":id/#{issuable_collection_name}/:#{issuable_key}/time_stats" do
        authorize! read_issuable_key, load_issuable

        present load_issuable, with: Entities::IssuableTimeStats
      end
    end
  end
end
