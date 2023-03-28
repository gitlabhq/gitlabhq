# frozen_string_literal: true

module Admin
  class AbuseReportEntity < Grape::Entity
    include RequestAwareEntity

    expose :category
    expose :updated_at

    expose :reported_user do |report|
      UserEntity.represent(report.user, only: [:name])
    end

    expose :reporter do |report|
      UserEntity.represent(report.reporter, only: [:name])
    end

    expose :reported_user_path do |report|
      user_path(report.user)
    end

    expose :reporter_path do |report|
      user_path(report.reporter)
    end

    expose :user_blocked do |report|
      report.user.blocked?
    end

    expose :block_user_path do |report|
      block_admin_user_path(report.user)
    end

    expose :remove_report_path do |report|
      admin_abuse_report_path(report)
    end

    expose :remove_user_and_report_path do |report|
      admin_abuse_report_path(report, remove_user: true)
    end
  end
end
