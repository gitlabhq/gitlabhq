# frozen_string_literal: true

module Ci
  class Resource < ApplicationRecord
    extend Gitlab::Ci::Model

    belongs_to :resource_group, class_name: 'Ci::ResourceGroup', inverse_of: :resources
    belongs_to :build, class_name: 'Ci::Build', inverse_of: :resource

    scope :free, -> { where(build: nil) }
    scope :retained_by, -> (build) { where(build: build) }
  end
end
