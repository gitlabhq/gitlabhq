# frozen_string_literal: true

class ProjectHookPolicy < ::BasePolicy
  delegate { @subject.project }
end
