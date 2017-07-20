module EE
  module MergeRequest
    extend ActiveSupport::Concern

    include ::Approvable

    included do
      has_many :approvals, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approvers, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approver_groups, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

      delegate :codeclimate_artifact, to: :head_pipeline, prefix: :head, allow_nil: true
      delegate :codeclimate_artifact, to: :base_pipeline, prefix: :base, allow_nil: true
    end

    def ff_merge_possible?
      project.repository.is_ancestor?(target_branch_sha, diff_head_sha)
    end

    def should_be_rebased?
      project.feature_available?(:merge_request_rebase) &&
        project.ff_merge_must_be_possible? &&
        !ff_merge_possible?
    end

    def rebase_dir_path
      File.join(::Gitlab.config.shared.path, 'tmp/rebase', source_project.id.to_s, id.to_s).to_s
    end

    def squash_dir_path
      File.join(::Gitlab.config.shared.path, 'tmp/squash', source_project.id.to_s, id.to_s).to_s
    end

    def rebase_in_progress?
      # The source project can be deleted
      return false unless source_project

      File.exist?(rebase_dir_path) && !clean_stuck_rebase
    end

    def squash_in_progress?
      # The source project can be deleted
      return false unless source_project

      File.exist?(squash_dir_path) && !clean_stuck_squash
    end

    def clean_stuck_rebase
      if File.mtime(rebase_dir_path) < 15.minutes.ago
        FileUtils.rm_rf(rebase_dir_path)
        true
      end
    end

    def clean_stuck_squash
      if File.mtime(squash_dir_path) < 15.minutes.ago
        FileUtils.rm_rf(squash_dir_path)
        true
      end
    end

    def squash
      super && project.feature_available?(:merge_request_squash)
    end
    alias_method :squash?, :squash

    def supports_weight?
      false
    end

    def has_codeclimate_data?
      !!(head_codeclimate_artifact&.success? &&
         base_codeclimate_artifact&.success?)
    end
  end
end
