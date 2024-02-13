# frozen_string_literal: true

module Ci
  module Catalog
    class VerifiedNamespace < ::ApplicationRecord
      self.table_name = 'catalog_verified_namespaces'

      belongs_to :namespace

      enum verification_level: { gitlab_maintained: 100, partner: 50, verified_creator: 10, unverified: 0 }

      validates :namespace_id, presence: true, uniqueness: true
    end
  end
end
