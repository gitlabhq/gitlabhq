# frozen_string_literal: true

module VirtualRegistries
  module Packages
    module Maven
      class RegistryUpstream < ApplicationRecord
        belongs_to :group
        belongs_to :registry, class_name: 'VirtualRegistries::Packages::Maven::Registry', inverse_of: :registry_upstream
        belongs_to :upstream, class_name: 'VirtualRegistries::Packages::Maven::Upstream', inverse_of: :registry_upstream

        validates :registry_id, :upstream_id, uniqueness: true
        validates :group, top_level_group: true, presence: true
      end
    end
  end
end
