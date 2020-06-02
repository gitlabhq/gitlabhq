# frozen_string_literal: true

class Releases::Evidence < ApplicationRecord
  include ShaAttribute
  include Presentable

  belongs_to :release, inverse_of: :evidences

  default_scope { order(created_at: :asc) }

  sha_attribute :summary_sha
  alias_attribute :collected_at, :created_at

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
end
