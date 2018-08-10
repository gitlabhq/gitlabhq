# frozen_string_literal: true
module ProtectedEnvironments
  class SearchService < BaseService
    # Returns unprotected environments filtered by name
    # Limited to 20 per performance reasons
    def execute(name)
      project
        .environments
        .where.not(name: project.protected_environments.select(:name))
        .where('environments.name LIKE ?', "#{name}%")
        .order_by_last_deployed_at
        .limit(20)
        .pluck(:name)
    end
  end
end
