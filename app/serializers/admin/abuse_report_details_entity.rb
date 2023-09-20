# frozen_string_literal: true

module Admin
  class AbuseReportDetailsEntity < Grape::Entity
    include RequestAwareEntity

    expose :user, if: ->(report) { report.user } do
      expose :details, merge: true do |report|
        UserEntity.represent(report.user, only: [:name, :username, :avatar_url, :email, :created_at, :last_activity_on])
      end

      expose :path do |report|
        user_path(report.user)
      end

      expose :admin_path do |report|
        admin_user_path(report.user)
      end

      expose :plan do |report|
        if Gitlab::CurrentSettings.current_application_settings.try(:should_check_namespace_plan?)
          report.user.namespace&.actual_plan&.title
        end
      end

      expose :verification_state do
        expose :email do |report|
          report.user.confirmed?
        end
        expose :phone do |report|
          report.user.phone_number_validation.present? && report.user.phone_number_validation.validated?
        end
        expose :credit_card do |report|
          report.user.credit_card_validation.present?
        end
      end

      expose :credit_card, if: ->(report) { report.user.credit_card_validation&.holder_name } do
        expose :name do |report|
          report.user.credit_card_validation.holder_name
        end
        expose :similar_records_count do |report|
          report.user.credit_card_validation.similar_records.count
        end
        expose :card_matches_link do |report|
          card_match_admin_user_path(report.user) if Gitlab.ee?
        end
      end

      expose :past_closed_reports do |report|
        AbuseReportEntity.represent(report.past_closed_reports_for_user, only: [:created_at, :category, :report_path])
      end

      expose :similar_open_reports, if: ->(report) { report.open? } do |report|
        ReportedContentEntity.represent(report.similar_open_reports_for_user)
      end

      expose :most_used_ip do |report|
        AuthenticationEvent.most_used_ip_address_for_user(report.user)
      end

      expose :last_sign_in_ip do |report|
        report.user.last_sign_in_ip
      end

      expose :snippets_count do |report|
        report.user.snippets.count
      end

      expose :groups_count do |report|
        report.user.groups.count
      end

      expose :notes_count do |report|
        report.user.notes.count
      end
    end

    expose :report do |report|
      ReportedContentEntity.represent(report)
    end
  end
end
