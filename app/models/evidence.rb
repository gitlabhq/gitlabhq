# frozen_string_literal: true

class Evidence < ApplicationRecord
  include ShaAttribute

  belongs_to :release

  before_validation :generate_summary_and_sha

  default_scope { order(created_at: :asc) }

  sha_attribute :summary_sha

  def milestones
    @milestones ||= release.milestones.includes(:issues)
  end

  ##
  # Return `summary` without sensitive information.
  #
  # Removing issues from summary in order to prevent leaking confidential ones.
  # See more https://gitlab.com/gitlab-org/gitlab/issues/121930
  def summary
    safe_summary = read_attribute(:summary)

    safe_summary.dig('release', 'milestones')&.each do |milestone|
      milestone.delete('issues')
    end

    safe_summary
  end

  private

  def generate_summary_and_sha
    summary = Evidences::EvidenceSerializer.new.represent(self) # rubocop: disable CodeReuse/Serializer
    return unless summary

    self.summary = summary
    self.summary_sha = Gitlab::CryptoHelper.sha256(summary)
  end
end
