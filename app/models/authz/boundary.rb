# frozen_string_literal: true

module Authz
  class Boundary
    def self.for(boundary)
      strategy_class = case boundary
                       when ::Group
                         GroupBoundary
                       when ::Project
                         ProjectBoundary
                       when ::User
                         UserBoundary
                       when nil
                         InstanceBoundary
                       end

      strategy_class.new(boundary)
    end

    class Base
      def self.declarative_policy_class
        'Authz::BoundaryPolicy'
      end

      def initialize(boundary)
        @boundary = boundary
      end

      def namespace
        boundary
      end

      def path
        namespace&.full_path
      end

      def instance_type?
        false
      end

      private

      attr_reader :boundary
    end

    class GroupBoundary < Base
    end

    class ProjectBoundary < Base
      def namespace
        boundary.project_namespace
      end
    end

    class UserBoundary < Base
      def namespace
        boundary.namespace
      end
    end

    class InstanceBoundary < Base
      def path
        'instance'
      end

      def instance_type?
        true
      end
    end
  end
end
