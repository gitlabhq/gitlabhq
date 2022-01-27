# frozen_string_literal: true

module Ci
  class ProjectPipelinesPolicy < BasePolicy
    delegate { @subject.project }
  end
end
