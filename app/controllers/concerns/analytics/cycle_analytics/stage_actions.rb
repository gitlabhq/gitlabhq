# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module StageActions
      include Gitlab::Utils::StrongMemoize
      extend ActiveSupport::Concern

      included do
        extend ::Gitlab::Utils::Override
        include CycleAnalyticsParams

        before_action :validate_params, except: %i[index]
        before_action :authorize_stage, except: %i[index]
      end

      def index
        result = list_service.execute

        if result.success?
          render json: cycle_analytics_configuration(result.payload[:stages])
        else
          render json: { message: result.message }, status: result.http_status
        end
      end

      def median
        render json: { value: data_collector.median.seconds }
      end

      def average
        render json: { value: data_collector.average.seconds }
      end

      def records
        serialized_records = data_collector.serialized_records do |relation|
          add_pagination_headers(relation)
        end

        render json: serialized_records
      end

      def count
        render json: { count: data_collector.count }
      end

      private

      def namespace
        raise NotImplementedError
      end

      def authorize_stage
        raise NotImplementedError
      end

      def add_pagination_headers(relation)
        Gitlab::Pagination::OffsetHeaderBuilder.new(
          request_context: self,
          per_page: relation.limit_value,
          page: relation.current_page,
          next_page: relation.next_page,
          prev_page: relation.prev_page,
          params: permitted_cycle_analytics_params
        ).execute(exclude_total_headers: true, data_without_counts: true)
      end

      def stage
        @stage ||= ::Analytics::CycleAnalytics::StageFinder.new(parent: namespace, stage_id: params[:id]).execute
      end

      def data_collector
        @data_collector ||= Gitlab::Analytics::CycleAnalytics::DataCollector.new(
          stage: stage,
          params: request_params.to_data_collector_params
        )
      end

      def value_stream
        @value_stream ||= Analytics::CycleAnalytics::ValueStream.build_default_value_stream(namespace)
      end

      def list_params
        { value_stream: value_stream }
      end

      def list_service
        Analytics::CycleAnalytics::Stages::ListService.new(
          parent: namespace,
          current_user: current_user,
          params: list_params
        )
      end

      def cycle_analytics_configuration(stages)
        stage_presenters = stages.map { |s| ::Analytics::CycleAnalytics::StagePresenter.new(s) }

        Analytics::CycleAnalytics::ConfigurationEntity.new(stages: stage_presenters)
      end
    end
  end
end

Analytics::CycleAnalytics::StageActions.prepend_mod_with('Analytics::CycleAnalytics::StageActions')
