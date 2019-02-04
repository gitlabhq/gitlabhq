# frozen_string_literal: true

class ResetProjectCacheService < BaseService
  def execute
    @project.increment!(:jobs_cache_index)
  end
end
