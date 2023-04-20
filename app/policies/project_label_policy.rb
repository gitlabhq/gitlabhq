# frozen_string_literal: true

class ProjectLabelPolicy < BasePolicy
  delegate { @subject.preloaded_parent_container }
end
