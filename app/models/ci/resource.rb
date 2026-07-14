# frozen_string_literal: true

module Ci
  class Resource < Ci::ApplicationRecord
    belongs_to :resource_group, class_name: 'Ci::ResourceGroup', inverse_of: :resources
    belongs_to :processable, class_name: 'Ci::Processable', foreign_key: 'build_id', inverse_of: :resource

    scope :free, -> { where(processable: nil) }
    scope :retained, -> { where.not(processable: nil) }
    scope :retained_by, ->(processable) { where(processable: processable) }
  end
end
