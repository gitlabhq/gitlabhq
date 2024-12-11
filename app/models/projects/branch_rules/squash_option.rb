# frozen_string_literal: true

module Projects
  module BranchRules
    class SquashOption < ApplicationRecord
      include ::Projects::SquashOption

      belongs_to :protected_branch, optional: false
      belongs_to :project, optional: false
    end
  end
end
