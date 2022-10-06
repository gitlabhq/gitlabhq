# frozen_string_literal: true

class ProjectLabelPolicy < BasePolicy
  delegate { @subject.parent_container }
end
