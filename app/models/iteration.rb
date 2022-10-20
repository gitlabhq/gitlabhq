# frozen_string_literal: true

# Placeholder class for model that is implemented in EE
class Iteration < ApplicationRecord
  include IgnorableColumns

  # TODO https://gitlab.com/gitlab-org/gitlab/-/issues/372125
  # TODO https://gitlab.com/gitlab-org/gitlab/-/issues/372126
  ignore_column :project_id, remove_with: '15.6', remove_after: '2022-09-17'

  self.table_name = 'sprints'

  def self.reference_prefix
    '*iteration:'
  end

  def self.reference_pattern
    nil
  end
end

Iteration.prepend_mod_with('Iteration')
