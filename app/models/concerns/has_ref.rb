# frozen_string_literal: true

module HasRef
  extend ActiveSupport::Concern

  def branch?
    !tag?
  end

  private

  def git_ref
    if branch?
      Gitlab::Git::BRANCH_REF_PREFIX + ref.to_s
    elsif tag?
      Gitlab::Git::TAG_REF_PREFIX + ref.to_s
    else
      raise ArgumentError, 'Invalid pipeline type!'
    end
  end
end
