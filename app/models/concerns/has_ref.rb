# frozen_string_literal: true

module HasRef
  extend ActiveSupport::Concern

  def branch?
    !tag? && !merge_request_event?
  end

  def git_ref
    if branch?
      Gitlab::Git::BRANCH_REF_PREFIX + ref.to_s
    elsif tag?
      Gitlab::Git::TAG_REF_PREFIX + ref.to_s
    end
  end
end
