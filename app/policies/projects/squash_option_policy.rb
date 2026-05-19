# frozen_string_literal: true

module Projects
  class SquashOptionPolicy < ::BasePolicy
    delegate { @subject.branch_rule }
  end
end
