# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      class RequestParams
        include ActiveModel::Model
        include ActiveModel::Validations
        include ActiveModel::Attributes
        include Gitlab::Utils::StrongMemoize

        MAX_RANGE_DAYS = 180.days.freeze
        DEFAULT_DATE_RANGE = 29.days # 30 including Date.today

        NEGATABLE_PARAMS = [
          :assignee_username,
          :author_username,
          :epic_id,
          :iteration_id,
          :label_name,
          :milestone_title,
          :my_reaction_emoji,
          :weight
        ].freeze

        LICENSED_PARAMS = [
          :weight,
          :epic_id,
          :my_reaction_emoji,
          :iteration_id
        ].freeze

        STRONG_PARAMS_DEFINITION = [
          :created_before,
          :created_after,
          :author_username,
          :milestone_title,
          :sort,
          :direction,
          :page,
          :stage_id,
          :end_event_filter,
          *LICENSED_PARAMS,
          { label_name: [].freeze,
            assignee_username: [].freeze,
            project_ids: [].freeze,
            not: NEGATABLE_PARAMS }
        ].freeze

        FINDER_PARAM_NAMES = [
          :assignee_username,
          :author_username,
          :milestone_title,
          :label_name
        ].freeze

        attr_writer :project_ids

        attribute :created_after, :datetime
        attribute :created_before, :datetime
        attribute :namespace
        attribute :current_user
        attribute :value_stream
        attribute :sort
        attribute :direction
        attribute :page
        attribute :stage_id
        attribute :end_event_filter
        attribute :weight
        attribute :epic_id
        attribute :my_reaction_emoji
        attribute :iteration_id
        attribute :not, default: -> { {} }

        FINDER_PARAM_NAMES.each do |param_name|
          attribute param_name
        end

        validates :created_after, presence: true
        validates :created_before, presence: true

        validate :validate_created_before
        validate :validate_date_range

        def initialize(params = {})
          super(params)

          self.created_before = (self.created_before || Time.current).at_end_of_day
          self.created_after = (created_after || default_created_after).at_beginning_of_day
          self.end_event_filter ||= Gitlab::Analytics::CycleAnalytics::BaseQueryBuilder::DEFAULT_END_EVENT_FILTER
        end

        def to_data_collector_params
          {
            current_user: current_user,
            from: created_after,
            to: created_before,
            project_ids: project_ids,
            sort: sort&.to_sym,
            direction: direction&.to_sym,
            page: page,
            end_event_filter: end_event_filter.to_sym,
            use_aggregated_data_collector: use_aggregated_backend?
          }.merge(attributes.symbolize_keys.slice(*FINDER_PARAM_NAMES))
        end

        def to_data_attributes
          {}.tap do |attrs|
            attrs[:value_stream] = value_stream_data_attributes.to_json if value_stream
            attrs[:created_after] = created_after.to_date.iso8601
            attrs[:created_before] = created_before.to_date.iso8601
            attrs[:labels] = label_name.to_json if label_name.present?
            attrs[:assignees] = assignee_username.to_json if assignee_username.present?
            attrs[:author] = author_username if author_username.present?
            attrs[:milestone] = milestone_title if milestone_title.present?
            attrs[:sort] = sort if sort.present?
            attrs[:direction] = direction if direction.present?
            attrs[:stage] = stage_data_attributes.to_json if stage_id.present?
            attrs[:namespace] = namespace_attributes
            attrs[:enable_tasks_by_type_chart] = 'false'
            attrs[:enable_customizable_stages] = 'false'
            attrs[:can_edit] = 'false'
            attrs[:enable_projects_filter] = 'false'
            attrs[:enable_vsd_link] = 'false'
            attrs[:default_stages] = Gitlab::Analytics::CycleAnalytics::DefaultStages.all.map do |stage_params|
              ::Analytics::CycleAnalytics::StagePresenter.new(stage_params)
            end.to_json

            attrs.merge!(foss_project_level_params, resource_paths)
          end
        end

        def project_ids
          Array(@project_ids)
        end

        def resource_paths
          helpers = ActionController::Base.helpers

          {}.tap do |paths|
            paths[:empty_state_svg_path] = helpers.image_path("illustrations/empty-state/empty-dashboard-md.svg")
            paths[:no_data_svg_path] = helpers.image_path("illustrations/empty-state/empty-dashboard-md.svg")
            paths[:no_access_svg_path] = helpers.image_path("illustrations/empty-state/empty-access-md.svg")

            if project
              paths[:milestones_path] = url_helpers.project_milestones_path(project, format: :json)
              paths[:labels_path] = url_helpers.project_labels_path(project, format: :json)
            end
          end
        end

        private

        delegate :url_helpers, to: Gitlab::Routing

        def foss_project_level_params
          return {} unless project

          {
            project_id: project.id,
            group_path: project.group ? "groups/#{project.group&.full_path}" : nil,
            request_path: url_helpers.project_cycle_analytics_path(project),
            full_path: project.full_path
          }
        end

        # FOSS version doesn't use the aggregated VSA backend
        def use_aggregated_backend?
          false
        end

        def namespace_attributes
          return {} unless project

          {
            name: project.name,
            type: namespace.type,
            path: project.full_path,
            rest_api_request_path: project.full_path
          }
        end

        def value_stream_data_attributes
          {
            id: value_stream.id,
            name: value_stream.name,
            is_custom: value_stream.custom?
          }
        end

        def stage_data_attributes
          return unless stage

          {
            id: stage.id || stage.name,
            title: stage.name
          }
        end

        def validate_created_before
          return if created_after.nil? || created_before.nil?

          errors.add(:created_before, :invalid) if created_after > created_before
        end

        def validate_date_range
          return if created_after.nil? || created_before.nil?

          time_period = created_before.at_beginning_of_day - created_after.at_beginning_of_day
          if time_period > MAX_RANGE_DAYS
            errors.add(:created_after, s_('CycleAnalytics|The given date range is larger than 180 days'))
          end
        end

        def default_created_after
          if created_before
            (created_before - DEFAULT_DATE_RANGE)
          else
            DEFAULT_DATE_RANGE.ago
          end
        end

        def stage
          return unless value_stream

          strong_memoize(:stage) do
            ::Analytics::CycleAnalytics::StageFinder.new(parent: namespace, stage_id: stage_id).execute if stage_id
          end
        end

        def project
          strong_memoize(:project) do
            namespace.project if namespace.is_a?(Namespaces::ProjectNamespace)
          end
        end
      end
    end
  end
end

Gitlab::Analytics::CycleAnalytics::RequestParams.prepend_mod_with('Gitlab::Analytics::CycleAnalytics::RequestParams')
