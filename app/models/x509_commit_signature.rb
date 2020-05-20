# frozen_string_literal: true

class X509CommitSignature < ApplicationRecord
  include ShaAttribute

  sha_attribute :commit_sha

  enum verification_status: {
    unverified: 0,
    verified: 1
  }

  belongs_to :project, class_name: 'Project', foreign_key: 'project_id', optional: false
  belongs_to :x509_certificate, class_name: 'X509Certificate', foreign_key: 'x509_certificate_id', optional: false

  validates :commit_sha, presence: true
  validates :project_id, presence: true
  validates :x509_certificate_id, presence: true

  scope :by_commit_sha, ->(shas) { where(commit_sha: shas) }

  def self.safe_create!(attributes)
    create_with(attributes)
      .safe_find_or_create_by!(commit_sha: attributes[:commit_sha])
  end

  # Find commits that are lacking a signature in the database at present
  def self.unsigned_commit_shas(commit_shas)
    return [] if commit_shas.empty?

    signed = by_commit_sha(commit_shas).pluck(:commit_sha)
    commit_shas - signed
  end

  def commit
    project.commit(commit_sha)
  end

  def x509_commit
    return unless commit

    Gitlab::X509::Commit.new(commit)
  end

  def user
    commit.committer
  end
end
