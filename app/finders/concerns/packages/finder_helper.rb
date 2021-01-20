# frozen_string_literal: true

module Packages
  module FinderHelper
    extend ActiveSupport::Concern

    private

    def packages_visible_to_user(user, within_group:)
      return ::Packages::Package.none unless within_group
      return ::Packages::Package.none unless Ability.allowed?(user, :read_package, within_group)

      projects = projects_visible_to_reporters(user, within_group.self_and_descendants.select(:id))
      ::Packages::Package.for_projects(projects.select(:id))
    end

    def projects_visible_to_user(user, within_group:)
      return ::Project.none unless within_group
      return ::Project.none unless Ability.allowed?(user, :read_package, within_group)

      projects_visible_to_reporters(user, within_group.self_and_descendants.select(:id))
    end

    def projects_visible_to_reporters(user, namespace_ids)
      ::Project.in_namespace(namespace_ids)
               .public_or_visible_to_user(user, ::Gitlab::Access::REPORTER)
    end
  end
end
