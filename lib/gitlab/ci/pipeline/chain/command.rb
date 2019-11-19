# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        Command = Struct.new(
          :source, :project, :current_user,
          :origin_ref, :checkout_sha, :after_sha, :before_sha, :source_sha, :target_sha,
          :trigger_request, :schedule, :merge_request, :external_pull_request,
          :ignore_skip_ci, :save_incompleted,
          :seeds_block, :variables_attributes, :push_options,
          :chat_data, :allow_mirror_update,
          # These attributes are set by Chains during processing:
          :config_content, :config_processor, :stage_seeds
        ) do
          include Gitlab::Utils::StrongMemoize

          def initialize(**params)
            params.each do |key, value|
              self[key] = value
            end
          end

          def uses_unsupported_legacy_trigger?
            trigger_request.present? &&
              trigger_request.trigger.legacy? &&
              !trigger_request.trigger.supports_legacy_tokens?
          end

          def branch_exists?
            strong_memoize(:is_branch) do
              project.repository.branch_exists?(ref)
            end
          end

          def tag_exists?
            strong_memoize(:is_tag) do
              project.repository.tag_exists?(ref)
            end
          end

          def merge_request_ref_exists?
            strong_memoize(:merge_request_ref_exists) do
              MergeRequest.merge_request_ref?(origin_ref) &&
                project.repository.ref_exists?(origin_ref)
            end
          end

          def ref
            strong_memoize(:ref) do
              Gitlab::Git.ref_name(origin_ref)
            end
          end

          def sha
            strong_memoize(:sha) do
              project.commit(origin_sha || origin_ref).try(:id)
            end
          end

          def origin_sha
            checkout_sha || after_sha
          end

          def before_sha
            self[:before_sha] || checkout_sha || Gitlab::Git::BLANK_SHA
          end

          def protected_ref?
            strong_memoize(:protected_ref) do
              project.protected_for?(origin_ref)
            end
          end

          def ambiguous_ref?
            strong_memoize(:ambiguous_ref) do
              project.repository.ambiguous_ref?(origin_ref)
            end
          end
        end
      end
    end
  end
end
