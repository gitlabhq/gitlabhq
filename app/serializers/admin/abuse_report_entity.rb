# frozen_string_literal: true

module Admin
  class AbuseReportEntity < Grape::Entity
    expose :category
    expose :updated_at

    expose :reported_user do |report|
      UserEntity.represent(report.user, only: [:name])
    end

    expose :reporter do |report|
      UserEntity.represent(report.reporter, only: [:name])
    end
  end
end
