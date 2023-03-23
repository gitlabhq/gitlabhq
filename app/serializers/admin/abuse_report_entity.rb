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
  end
end
