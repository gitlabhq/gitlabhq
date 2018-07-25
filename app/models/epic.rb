# frozen_string_literal: true

# Placeholder class for model that is implemented in EE
# It reserves '&' as a reference prefix, but the table does not exists in CE
class Epic < ActiveRecord::Base
  prepend EE::Epic

  def self.reference_prefix
    '&'
  end

  def self.reference_prefix_escaped
    '&amp;'
  end
end
