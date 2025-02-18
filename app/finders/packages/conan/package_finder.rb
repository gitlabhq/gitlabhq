# frozen_string_literal: true

module Packages
  module Conan
    class PackageFinder
      include Gitlab::Utils::StrongMemoize
      include ActiveRecord::Sanitization::ClassMethods

      MAX_PACKAGES_COUNT = 500
      WILDCARD = '*'
      SQL_WILDCARD = '%'

      def initialize(current_user, params, project: nil)
        @current_user = current_user
        @name, @version, @username, _ = params[:query].to_s.split(%r{[@/]}).map { |q| sanitize_sql(q) }
        @project = project
      end

      def execute
        return ::Packages::Conan::Package.none unless name.present?
        return ::Packages::Conan::Package.none if name == SQL_WILDCARD && version == SQL_WILDCARD

        packages
      end

      private

      attr_reader :current_user, :name, :project, :version, :username

      def sanitize_sql(query)
        sanitize_sql_like(query).tr(WILDCARD, SQL_WILDCARD) unless query.nil?
      end

      def packages
        packages = base.installable.preload_conan_metadatum.with_name_like(name)
        packages = by_version(packages) if version.present?
        packages.limit_recent(MAX_PACKAGES_COUNT)
      end

      def by_version(packages)
        if version.include?(SQL_WILDCARD)
          packages.with_version_like(version)
        else
          packages.with_version(version)
        end
      end

      def base
        ::Packages::Conan::Package.for_projects(project || projects_available_in_current_context)
      end

      def projects_available_in_current_context
        return ::Project.public_or_visible_to_user(current_user, project_min_access_level) unless username.present?

        return project_from_path if can_access_project_package?

        nil
      end

      def project_from_path
        Project.find_by_full_path(full_path)
      end
      strong_memoize_attr :project_from_path

      def full_path
        ::Packages::Conan::Metadatum.full_path_from(package_username: username)
      end

      def can_access_project_package?
        Ability.allowed?(current_user, :read_package, project_from_path.try(:packages_policy_subject))
      end

      def project_min_access_level
        return ::Gitlab::Access::GUEST if Feature.enabled?(:allow_guest_plus_roles_to_pull_packages, current_user)

        ::Gitlab::Access::REPORTER
      end
    end
  end
end
