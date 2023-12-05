# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class AutoCancel < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Attributable
          include ::Gitlab::Config::Entry::Validatable

          ALLOWED_KEYS = %i[on_new_commit].freeze
          ALLOWED_ON_NEW_COMMIT_OPTIONS = ::Ci::PipelineMetadata.auto_cancel_on_new_commits.keys.freeze

          attributes ALLOWED_KEYS

          validations do
            validates :config, type: Hash, allowed_keys: ALLOWED_KEYS
            validates :on_new_commit, allow_nil: true, type: String, inclusion: {
              in: ALLOWED_ON_NEW_COMMIT_OPTIONS,
              message: format(_("must be one of: %{values}"), values: ALLOWED_ON_NEW_COMMIT_OPTIONS.join(', '))
            }
          end
        end
      end
    end
  end
end
