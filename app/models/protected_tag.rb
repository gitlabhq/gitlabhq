# frozen_string_literal: true

class ProtectedTag < ApplicationRecord
  include ProtectedRef
  include EachBatch

  validates :name, uniqueness: { scope: :project_id }
  validates :project, presence: true

  scope :preload_access_levels, -> { preload(:create_access_levels) }

  protected_ref_access_levels :create

  def self.protected?(project, ref_name)
    return false if ref_name.blank?

    refs = Gitlab::SafeRequestStore.fetch("protected-tag:#{project.cache_key}:refs") do
      project.protected_tags.select(:name)
    end

    self.matching(ref_name, protected_refs: refs).present?
  end
end
