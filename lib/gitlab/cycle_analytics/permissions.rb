# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class Permissions
      STAGE_PERMISSIONS = {
        issue: :read_issue,
        code: :read_merge_request,
        test: :read_build,
        review: :read_merge_request,
        staging: :read_build,
        production: :read_issue
      }.freeze

      def self.get(*args)
        new(*args).get
      end

      def initialize(user:, project:)
        @user = user
        @project = project
        @stage_permission_hash = {}
      end

      def get
        ::CycleAnalytics::BaseMethods::STAGES.each do |stage|
          @stage_permission_hash[stage] = authorized_stage?(stage)
        end

        @stage_permission_hash
      end

      private

      def authorized_stage?(stage)
        return false unless authorize_project(:read_cycle_analytics)

        STAGE_PERMISSIONS[stage] ? authorize_project(STAGE_PERMISSIONS[stage]) : true
      end

      def authorize_project(permission)
        Ability.allowed?(@user, permission, @project)
      end
    end
  end
end
