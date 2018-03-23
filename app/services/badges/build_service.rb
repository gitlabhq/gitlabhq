module Badges
  class BuildService < Badges::BaseService
    # returns the created badge
    def execute(source)
      if source.is_a?(Group)
        GroupBadge.new(params.merge(group: source))
      else
        ProjectBadge.new(params.merge(project: source))
      end
    end
  end
end
