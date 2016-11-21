module Gitlab
  module CycleAnalytics
    class Permissions
      STAGE_PERMISSIONS = {
        read_build: [:test, :staging],
        read_issue: [:issue, :production],
        read_merge_request: [:code, :review]
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
        ::CycleAnalytics::STAGES.each do |stage|
          @stage_permission_hash[stage] = authorized_stage?(stage)
        end

        @stage_permission_hash
      end

      private

      def authorized_stage?(stage)
        return false unless authorize_project(:read_cycle_analytics)

        permissions_for_stage(stage).keys.each do |permission|
          return false unless authorize_project(permission)
        end

        true
      end

      def permissions_for_stage(stage)
        STAGE_PERMISSIONS.select { |_permission, stages| stages.include?(stage) }
      end

      def authorize_project(permission)
        Ability.allowed?(@user, permission, @project)
      end
    end
  end
end
