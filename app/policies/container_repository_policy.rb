# frozen_string_literal: true

class ContainerRepositoryPolicy < BasePolicy
  delegate { @subject.project }
end
