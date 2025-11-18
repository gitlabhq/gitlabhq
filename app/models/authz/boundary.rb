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
                         NilBoundary
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

      def member?(user)
        boundary.member?(user)
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

      def member?(user)
        namespace.member?(user)
      end
    end

    class NilBoundary < Base
      def namespace
        nil
      end

      def path
        nil
      end

      def member?(_)
        true
      end
    end
  end
end
