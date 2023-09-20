# frozen_string_literal: true

module Admin
  class ReportedContentEntity < Grape::Entity
    include RequestAwareEntity

    expose :id
    expose :global_id do |report|
      Gitlab::GlobalId.build(report, id: report.id).to_s
    end
    expose :status
    expose :message
    expose :created_at, as: :reported_at
    expose :category
    expose :report_type, as: :type
    expose :reported_content, as: :content
    expose :reported_from_url, as: :url
    expose :screenshot_path, as: :screenshot

    expose :reporter, if: ->(report) { report.reporter } do
      expose :details, merge: true do |report|
        UserEntity.represent(report.reporter, only: [:name, :username, :avatar_url])
      end

      expose :path do |report|
        user_path(report.reporter)
      end
    end

    expose :update_path do |report|
      admin_abuse_report_path(report)
    end

    expose :moderate_user_path do |report|
      moderate_user_admin_abuse_report_path(report)
    end
  end
end
