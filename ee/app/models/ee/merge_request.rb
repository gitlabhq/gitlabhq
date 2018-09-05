module EE
  module MergeRequest
    extend ActiveSupport::Concern

    include ::Approvable

    included do
      has_many :approvals, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approved_by_users, through: :approvals, source: :user
      has_many :approvers, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approver_groups, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

      # codeclimate_artifact is deprecated and replaced with code_quality_artifact (#5779)
      delegate :codeclimate_artifact, to: :head_pipeline, prefix: :head, allow_nil: true
      delegate :codeclimate_artifact, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :code_quality_artifact, to: :head_pipeline, prefix: :head, allow_nil: true
      delegate :code_quality_artifact, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :performance_artifact, to: :head_pipeline, prefix: :head, allow_nil: true
      delegate :performance_artifact, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :sast_artifact, to: :head_pipeline, prefix: :head, allow_nil: true
      delegate :sast_artifact, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :dependency_scanning_artifact, to: :head_pipeline, prefix: :head, allow_nil: true
      delegate :dependency_scanning_artifact, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :license_management_artifact, to: :head_pipeline, prefix: :head, allow_nil: true
      delegate :license_management_artifact, to: :base_pipeline, prefix: :base, allow_nil: true
      # sast_container_artifact is deprecated and replaced with container_scanning_artifact (#5778)
      delegate :sast_container_artifact, to: :head_pipeline, prefix: :head, allow_nil: true
      delegate :sast_container_artifact, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :container_scanning_artifact, to: :head_pipeline, prefix: :head, allow_nil: true
      delegate :container_scanning_artifact, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :dast_artifact, to: :head_pipeline, prefix: :head, allow_nil: true
      delegate :dast_artifact, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :sha, to: :head_pipeline, prefix: :head_pipeline, allow_nil: true
      delegate :sha, to: :base_pipeline, prefix: :base_pipeline, allow_nil: true
      delegate :has_sast_data?, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :has_dependency_scanning_data?, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :has_license_management_data?, to: :base_pipeline, prefix: :base, allow_nil: true
      # has_sast_container_data? is deprecated and replaced with has_container_scanning_data? (#5778)
      delegate :has_sast_container_data?, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :has_container_scanning_data?, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :has_dast_data?, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :expose_sast_data?, to: :head_pipeline, allow_nil: true
      delegate :expose_dependency_scanning_data?, to: :head_pipeline, allow_nil: true
      delegate :expose_license_management_data?, to: :head_pipeline, allow_nil: true
      # expose_sast_container_data? is deprecated and replaced with expose_container_scanning_data? (#5778)
      delegate :expose_sast_container_data?, to: :head_pipeline, allow_nil: true
      delegate :expose_container_scanning_data?, to: :head_pipeline, allow_nil: true
      delegate :expose_dast_data?, to: :head_pipeline, allow_nil: true
      delegate :merge_requests_author_approval?, to: :target_project, allow_nil: true

      participant :participant_approvers
    end

    def supports_weight?
      false
    end

    # expose_codeclimate_data? is deprecated and replaced with expose_code_quality_data? (#5779)
    def expose_codeclimate_data?
      !!(head_pipeline&.expose_codeclimate_data? &&
         base_pipeline&.expose_codeclimate_data?)
    end

    def expose_code_quality_data?
      !!(head_pipeline&.expose_code_quality_data? &&
         base_pipeline&.expose_code_quality_data?)
    end

    def expose_performance_data?
      !!(head_pipeline&.expose_performance_data? &&
         base_pipeline&.expose_performance_data?)
    end

    def validate_approvals_before_merge
      return true unless approvals_before_merge
      return true unless target_project

      # Ensure per-merge-request approvals override is valid
      if approvals_before_merge >= target_project.approvals_before_merge
        true
      else
        errors.add :validate_approvals_before_merge,
                   'Number of approvals must be at least that of approvals on the target project'
      end
    end

    def participant_approvers
      approval_needed? ? approvers_left : []
    end
  end
end
