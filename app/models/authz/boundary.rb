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

    def self.strategy_for_type(type)
      case type&.to_sym
      when :project
        ProjectBoundary
      when :group
        GroupBoundary
      end
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

      def root_namespace_id
        namespace&.traversal_ids&.first
      end

      def type_label
        access.to_s.tr('_', ' ')
      end

      def visible_to?(_user)
        true
      end

      attr_reader :boundary
    end

    class GroupBoundary < Base
      def self.record_class
        ::Group
      end

      def self.namespace_association
        nil
      end

      def access
        GranularScope::Access::SELECTED_MEMBERSHIPS
      end

      def type_label
        'group'
      end

      def namespace
        boundary
      end

      def member?(user)
        boundary.member?(user)
      end

      def visible_to?(user)
        ::Gitlab::VisibilityLevel.levels_for_user(user).include?(boundary.visibility_level)
      end
    end

    class ProjectBoundary < Base
      def self.record_class
        ::Project
      end

      def self.namespace_association
        :project_namespace
      end

      def access
        GranularScope::Access::SELECTED_MEMBERSHIPS
      end

      def type_label
        'project'
      end

      def namespace
        boundary.project_namespace
      end

      def member?(user)
        boundary.member?(user)
      end

      def visible_to?(user)
        ::Gitlab::VisibilityLevel.levels_for_user(user).include?(boundary.visibility_level)
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
