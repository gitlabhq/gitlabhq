# frozen_string_literal: true

# Placeholder class for model that is implemented in EE
class Iterations::Cadence < ApplicationRecord
  self.table_name = 'iterations_cadences'
end

Iterations::Cadence.prepend_if_ee('::EE::Iterations::Cadence')
