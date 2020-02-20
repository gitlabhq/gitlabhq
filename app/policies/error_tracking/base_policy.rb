# frozen_string_literal: true

module ErrorTracking
  class BasePolicy < ::BasePolicy
    delegate { @subject.gitlab_project }
  end
end
