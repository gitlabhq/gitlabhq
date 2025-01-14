# frozen_string_literal: true

module CommitSignature
  extend ActiveSupport::Concern

  included do
    include ShaAttribute
    include EachBatch

    sha_attribute :commit_sha

    enum verification_status: Enums::CommitSignature.verification_statuses

    belongs_to :project, class_name: 'Project', foreign_key: 'project_id', optional: false

    validates :commit_sha, presence: true
    validates :project_id, presence: true

    scope :by_commit_sha, ->(shas) { where(commit_sha: shas) }
  end

  class_methods do
    def safe_create!(attributes)
      create_with(attributes)
        .safe_find_or_create_by!(commit_sha: attributes[:commit_sha])
    end

    # Find commits that are lacking a signature in the database at present
    def unsigned_commit_shas(commit_shas)
      return [] if commit_shas.empty?

      signed = by_commit_sha(commit_shas).pluck(:commit_sha)
      commit_shas - signed
    end
  end

  def commit
    project.commit(commit_sha)
  end

  def signed_by_user
    raise NoMethodError, 'must implement `signed_by_user` method'
  end

  def reverified_status
    return verification_status unless Feature.enabled?(:check_for_mailmapped_commit_emails, project)
    return verification_status unless verified? || verified_system?

    return 'unverified_author_email' if emails_for_verification&.exclude?(commit&.author_email)

    verification_status
  end

  private

  def emails_for_verification
    if x509?
      x509_certificate.all_emails
    else
      signed_by_user&.verified_emails
    end
  end
end
