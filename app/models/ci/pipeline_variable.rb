# frozen_string_literal: true

module Ci
  class PipelineVariable < Ci::ApplicationRecord
    include Ci::Partitionable
    include Ci::HasVariable
    include Ci::RawVariable

    include IgnorableColumns
    ignore_column :id_convert_to_bigint, remove_with: '16.3', remove_after: '2023-08-22'

    belongs_to :pipeline

    partitionable scope: :pipeline

    alias_attribute :secret_value, :value

    validates :key, :pipeline, presence: true

    def hook_attrs
      { key: key, value: value }
    end
  end
end
