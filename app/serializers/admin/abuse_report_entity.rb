# frozen_string_literal: true

module Admin
  class AbuseReportEntity < Grape::Entity
    include RequestAwareEntity

    expose :category
    expose :created_at
    expose :updated_at

    expose :reported_user do |report|
      UserEntity.represent(report.user, only: [:name])
    end

    expose :reporter do |report|
      UserEntity.represent(report.reporter, only: [:name])
    end

    expose :report_path do |report|
      admin_abuse_report_path(report)
    end
  end
end
