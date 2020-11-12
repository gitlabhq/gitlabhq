# frozen_string_literal: true

class ServicePolicy < BasePolicy
  delegate(:project)
end
