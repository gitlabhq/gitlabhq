# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class ValueStreamEntity < Grape::Entity
      expose :name
      expose :id
      expose :is_custom do |object|
        object.custom?
      end
      expose :stages, using: Analytics::CycleAnalytics::StageEntity

      private

      def id
        object.id || object.name # use the name `default` if the record is not persisted
      end

      def stages
        object.stages.map { |s| ::Analytics::CycleAnalytics::StagePresenter.new(s) } # rubocop: disable CodeReuse/Presenter
      end
    end
  end
end
