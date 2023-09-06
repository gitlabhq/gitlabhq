# frozen_string_literal: true

module DesignManagement
  DESIGN_IMAGE_SIZES = %w[v432x230].freeze

  def self.designs_directory
    'designs'
  end

  def self.table_name_prefix
    'design_management_'
  end
end
