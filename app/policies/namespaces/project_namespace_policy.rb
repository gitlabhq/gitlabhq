# frozen_string_literal: true

module Namespaces
  class ProjectNamespacePolicy < Namespaces::GroupProjectNamespaceSharedPolicy
    delegate(:project)

    rule { can?(:read_project) }.enable :read_namespace
    rule { ~can?(:read_project) }.prevent :read_namespace
  end
end
