# frozen_string_literal: true

# Placeholder class for model that is implemented in EE
class Iteration < ApplicationRecord
  self.table_name = 'sprints'

  def self.reference_prefix
    '*iteration:'
  end

  def self.reference_pattern
    nil
  end
end

Iteration.prepend_mod_with('Iteration')
