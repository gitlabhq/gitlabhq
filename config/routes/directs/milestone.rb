# frozen_string_literal: true

# @!method milestone_path(milestone, options = {})
# @!method milestone_url(milestone, options = {})
direct(:milestone) do |milestone, *args|
  if milestone.group_milestone?
    [milestone.group, milestone, *args]
  elsif milestone.project_milestone?
    [milestone.project, milestone, *args]
  end
end
