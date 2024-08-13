# frozen_string_literal: true

# Placeholder class for model that is implemented in EE
# It reserves '&' as a reference prefix, but the table does not exist in FOSS
class Epic < ApplicationRecord
  def self.link_reference_pattern
    nil
  end

  def self.reference_prefix
    '&'
  end

  def self.reference_prefix_escaped
    '&amp;'
  end
end

Epic.prepend_mod_with('Epic')
