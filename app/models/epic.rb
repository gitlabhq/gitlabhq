# frozen_string_literal: true

# Placeholder class for model that is implemented in EE
# It reserves '&' as a reference prefix, but the table does not exist in FOSS
class Epic < ApplicationRecord
  include IgnorableColumns

  ignore_column :health_status, remove_with: '13.0', remove_after: '2019-05-22'

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

Epic.prepend_if_ee('EE::Epic')
