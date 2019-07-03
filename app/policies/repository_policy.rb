# frozen_string_literal: true

class RepositoryPolicy < BasePolicy
  delegate { @subject.project }
end
