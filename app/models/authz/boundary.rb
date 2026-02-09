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
                         PersonalProjectsBoundary
                       when GranularScope::Access::ALL_MEMBERSHIPS,
                          GranularScope::Access::USER,
                          GranularScope::Access::INSTANCE
                         NilBoundary
                       end

      strategy_class&.new(boundary)
    end

    class Base
      def self.declarative_policy_class
        'Authz::BoundaryPolicy'
      end

      def initialize(boundary)
        @boundary = boundary
      end

      def path
        namespace&.full_path
      end

      attr_reader :boundary
    end

    class GroupBoundary < Base
      def access
        GranularScope::Access::SELECTED_MEMBERSHIPS
      end

      def namespace
        boundary
      end

      def member?(user)
        boundary.member?(user)
      end
    end

    class ProjectBoundary < Base
      def access
        GranularScope::Access::SELECTED_MEMBERSHIPS
      end

      def namespace
        boundary.project_namespace
      end

      def member?(user)
        boundary.member?(user)
      end
    end

    class PersonalProjectsBoundary < Base
      def access
        GranularScope::Access::PERSONAL_PROJECTS
      end

      def namespace
        boundary.namespace
      end

      def member?(user)
        namespace.member?(user)
      end
    end

    class NilBoundary < Base
      def access
        boundary
      end

      def namespace
        nil
      end

      def member?(_)
        true
      end

      def path
        nil
      end
    end
  end
end
