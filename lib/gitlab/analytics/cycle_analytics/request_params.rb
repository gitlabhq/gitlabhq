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
          label_name: [].freeze,
          assignee_username: [].freeze,
          project_ids: [].freeze
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
        attribute :group
        attribute :current_user
        attribute :value_stream
        attribute :sort
        attribute :direction
        attribute :page
        attribute :project
        attribute :stage_id
        attribute :end_event_filter

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

        def project_ids
          Array(@project_ids)
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
            end_event_filter: end_event_filter.to_sym
          }.merge(attributes.symbolize_keys.slice(*FINDER_PARAM_NAMES))
        end

        def to_data_attributes
          {}.tap do |attrs|
            attrs[:group] = group_data_attributes if group
            attrs[:value_stream] = value_stream_data_attributes.to_json if value_stream
            attrs[:created_after] = created_after.to_date.iso8601
            attrs[:created_before] = created_before.to_date.iso8601
            attrs[:projects] = group_projects(project_ids) if group && project_ids.present?
            attrs[:labels] = label_name.to_json if label_name.present?
            attrs[:assignees] = assignee_username.to_json if assignee_username.present?
            attrs[:author] = author_username if author_username.present?
            attrs[:milestone] = milestone_title if milestone_title.present?
            attrs[:sort] = sort if sort.present?
            attrs[:direction] = direction if direction.present?
            attrs[:stage] = stage_data_attributes.to_json if stage_id.present?
          end
        end

        private

        def group_data_attributes
          {
            id: group.id,
            name: group.name,
            parent_id: group.parent_id,
            full_path: group.full_path,
            avatar_url: group.avatar_url
          }
        end

        def value_stream_data_attributes
          {
            id: value_stream.id,
            name: value_stream.name,
            is_custom: value_stream.custom?
          }
        end

        def group_projects(project_ids)
          GroupProjectsFinder.new(
            group: group,
            current_user: current_user,
            options: { include_subgroups: true },
            project_ids_relation: project_ids
          )
            .execute
            .with_route
            .map { |project| project_data_attributes(project) }
            .to_json
        end

        def project_data_attributes(project)
          {
            id: project.to_gid.to_s,
            name: project.name,
            path_with_namespace: project.path_with_namespace,
            avatar_url: project.avatar_url
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

          if (created_before - created_after) > MAX_RANGE_DAYS
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
            ::Analytics::CycleAnalytics::StageFinder.new(parent: project || group, stage_id: stage_id).execute if stage_id
          end
        end
      end
    end
  end
end
