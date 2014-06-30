module Milestones
  class GroupService < Milestones::BaseService
    def initialize(project_milestones)
      @project_milestones = project_milestones.group_by(&:title)
    end

    def execute
      build(@project_milestones)
    end

    def milestone(title)
      if title
        group_milestone = @project_milestones[title].group_by(&:title)
        build(group_milestone).first
      else
        nil
      end
    end

    private

    def build(milestone)
      milestone.map{ |title, milestones| GroupMilestone.new(title, milestones) }
    end
  end
end
