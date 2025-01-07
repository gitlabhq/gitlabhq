# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class SkipCompanyOnboardingStep < BatchedMigrationJob
      operation_name :skip_company_onboarding_step
      feature_category :onboarding

      class UserDetail < ApplicationRecord
        self.table_name = :user_details

        belongs_to :user
      end

      def perform
        new_step_url = "#{Gitlab.config.gitlab.url}/users/sign_up/groups/new"

        onboarding_status = UserDetail.arel_table[:onboarding_status]
        registration_type_missing =
          Arel::Nodes::NamedFunction.new(
            'jsonb_exists',
            [onboarding_status, Arel::Nodes.build_quoted('registration_type')]
          ).not

        json_path = '$.step_url ? (@ like_regex ".*\/users\/sign_up\/company\/new.*")'
        company_step_url_exists = Arel::Nodes::NamedFunction.new(
          'jsonb_path_exists',
          [onboarding_status, Arel::Nodes.build_quoted(json_path)]
        )

        each_sub_batch do |sub_batch|
          UserDetail
            .where(user: eligible_users(sub_batch))
            .where(registration_type_missing)
            .where(company_step_url_exists)
            .update_all("onboarding_status = onboarding_status || jsonb_build_object('step_url', '#{new_step_url}')")
        end
      end

      private

      def eligible_users(sub_batch)
        sub_batch.where(onboarding_in_progress: true)
      end
    end
  end
end
