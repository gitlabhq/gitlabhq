# frozen_string_literal: true

module EarlyAccessProgram
  class Base < ::ApplicationRecord
    self.abstract_class = true
    self.table_name_prefix = 'early_access_program_'
  end
end
