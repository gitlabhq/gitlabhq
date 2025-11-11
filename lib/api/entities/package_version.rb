# frozen_string_literal: true

module API
  module Entities
    class PackageVersion < Grape::Entity
      expose :id
      expose :version
      expose :created_at
      expose :tags

      expose :pipeline, if: ->(package, opts) {
        package.last_build_info && can_read_pipeline?(package, opts)
      }, using: Package::Pipeline

      private

      def can_read_pipeline?(package, opts)
        Ability.allowed?(opts[:user], :read_pipeline, package.project)
      end
    end
  end
end
