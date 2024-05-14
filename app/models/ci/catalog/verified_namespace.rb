# frozen_string_literal: true

module Ci
  module Catalog
    class VerifiedNamespace < ::ApplicationRecord
      VERIFICATION_LEVELS = {
        gitlab_maintained: 100,
        gitlab_partner_maintained: 50,
        verified_creator_maintained: 10,
        unverified: 0
      }.freeze

      self.table_name = 'catalog_verified_namespaces'

      belongs_to :namespace

      enum verification_level: VERIFICATION_LEVELS

      validates :namespace_id, presence: true, uniqueness: true

      def self.for_project(project)
        find_by(namespace: project.root_namespace)
      end

      def self.find_or_create_by_namespace!(namespace)
        find_or_create_by!(namespace: namespace)
      end
    end
  end
end
