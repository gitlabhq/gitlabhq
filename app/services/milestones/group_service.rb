module Milestones
  class GroupService < Milestones::BaseService
    def initialize(group, user, project_milestones)
      @group = group
      @user = user
      @project_milestones = project_milestones.group_by(&:title)
    end

    def titles
      @project_milestones.map{ |title, milestone| title }
    end

    def project_names
      names = {}
      @project_milestones.map do |title, milestone|
        projects = milestone.map{|m| m.project.name }
        names.store(title, projects)
      end
      names
    end

    def issue_count
      @project_milestones.merge(@project_milestones){ |title, milestone| milestone.map{|m| m.issues.count }.sum }
    end

    def mr_count
      @project_milestones.merge(@project_milestones){ |title, milestone| milestone.map{|m| m.merge_requests.count }.sum }
    end

    def open_issues_count
      @project_milestones.merge(@project_milestones){ |title, milestone| milestone.map{|m| m.issues.opened.count }.sum }
    end

    def closed_issues_count
      @project_milestones.merge(@project_milestones){ |title, milestone| milestone.map{|m| m.issues.closed.count }.sum }
    end

    def open_mr_count
      @project_milestones.merge(@project_milestones){ |title, milestone| milestone.map{|m| m.merge_requests.opened.count }.sum }
    end

    def close_mr_count
      @project_milestones.merge(@project_milestones){ |title, milestone| milestone.map{|m| m.merge_requests.closed.count }.sum }
    end

    def open_items_count
      @project_milestones.merge(@project_milestones){ |title, milestone| milestone.map{|m| m.open_items_count }.sum }
    end

    def closed_items_count
      @project_milestones.merge(@project_milestones){ |title, milestone| milestone.map{|m| m.closed_items_count }.sum }
    end

    def total_items_count
      issue_count.merge(mr_count){ |title,issue,mr| issue + mr }
    end

    def percent_complete
      percentage_per_milestone = {}
      closed_items_count.map do |title, closed_items|
        total_items = total_items_count[title]
        percentage = begin
                       ((closed_items * 100) / total_items).abs
                     rescue  ZeroDivisionError
                       100
                     end
        percentage_per_milestone.store(title, percentage)
      end
      percentage_per_milestone
    end

  end
end
