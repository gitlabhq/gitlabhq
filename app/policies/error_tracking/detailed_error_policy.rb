# frozen_string_literal: true

module ErrorTracking
  class DetailedErrorPolicy < BasePolicy
    delegate { @subject.gitlab_project }
  end
end
