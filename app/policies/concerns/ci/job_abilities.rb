# frozen_string_literal: true

module Ci
  module JobAbilities
    extend ActiveSupport::Concern

    # TODO: remove usages of :update_build permission
    UPDATE_JOB_ABILITIES = %i[
      update_build
      play_job
      retry_job
      unschedule_job
      keep_job_artifacts
    ].freeze

    CLEANUP_JOB_ABILITIES = %i[
      cancel_build
      erase_build
    ].freeze

    class_methods do
      def all_job_update_abilities
        UPDATE_JOB_ABILITIES
      end

      def all_job_cleanup_abilities
        CLEANUP_JOB_ABILITIES
      end

      def all_job_write_abilities
        all_job_update_abilities + all_job_cleanup_abilities
      end

      # We exclude `update_build` because it's used as an internal abstraction that is used to
      # influence other permissions, like `erase_build`, etc.
      # Preventing `update_build` would cause other permissions like `erase_build` to be prevented.
      def job_user_facing_update_abilities
        all_job_update_abilities - [:update_build]
      end
    end
  end
end
