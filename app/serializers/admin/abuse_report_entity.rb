# frozen_string_literal: true

module Admin
  class AbuseReportEntity < Grape::Entity
    include RequestAwareEntity

    expose :category
    expose :created_at
    expose :updated_at
    expose :count
    expose :labels, using: AntiAbuse::Reports::LabelEntity, if: ->(*) { Feature.enabled?(:abuse_report_labels) }

    expose :reported_user do |report|
      UserEntity.represent(report.user, only: [:name])
    end

    expose :reporter do |report|
      UserEntity.represent(report.reporter, only: [:name])
    end

    expose :report_path do |report|
      admin_abuse_report_path(report)
    end

    private

    def count
      object.has_attribute?(:count) ? object.count : 1
    end
  end
end
