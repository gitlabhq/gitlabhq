class ResetProjectCacheService < BaseService
  def execute
    @project.increment!(:cache_index)
  end
end
