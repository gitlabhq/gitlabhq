module Milestones
  class GroupService < Milestones::BaseService
    def initialize(project_milestones)
      @project_milestones = project_milestones.group_by(&:title)
    end

    def execute
      @project_milestones.map{ |title, milestone| GroupMilestone.new(title, milestone) }
    end

  end
end
