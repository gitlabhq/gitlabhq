# frozen_string_literal: true

class ProjectStatisticsPolicy < BasePolicy
  delegate { @subject.project }
end
