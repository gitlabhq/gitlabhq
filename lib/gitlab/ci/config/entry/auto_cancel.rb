# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class AutoCancel < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Attributable
          include ::Gitlab::Config::Entry::Validatable

          ALLOWED_KEYS = %i[on_new_commit on_job_failure].freeze
          ALLOWED_ON_NEW_COMMIT_OPTIONS = ::Ci::PipelineMetadata.auto_cancel_on_new_commits.keys.freeze
          ALLOWED_ON_JOB_FAILURE_OPTIONS = ::Ci::PipelineMetadata.auto_cancel_on_job_failures.keys.freeze

          attributes ALLOWED_KEYS

          validations do
            validates :config, type: Hash, allowed_keys: ALLOWED_KEYS
            validates :on_new_commit, allow_nil: true, type: String, inclusion: {
              in: ALLOWED_ON_NEW_COMMIT_OPTIONS,
              message: format(_("must be one of: %{values}"), values: ALLOWED_ON_NEW_COMMIT_OPTIONS.join(', '))
            }
            validates :on_job_failure, allow_nil: true, type: String, inclusion: {
              in: ALLOWED_ON_JOB_FAILURE_OPTIONS,
              message: format(_("must be one of: %{values}"), values: ALLOWED_ON_JOB_FAILURE_OPTIONS.join(', '))
            }
          end
        end
      end
    end
  end
end
