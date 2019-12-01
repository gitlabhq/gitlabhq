# frozen_string_literal: true

# Placeholder class for model that is implemented in EE
# It reserves '&' as a reference prefix, but the table does not exists in CE
class Epic < ApplicationRecord
  include IgnorableColumns

  ignore_column :milestone_id, remove_after: '2019-12-15', remove_with: '12.7'

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
