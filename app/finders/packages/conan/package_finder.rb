# frozen_string_literal: true

module Packages
  module Conan
    class PackageFinder
      include Gitlab::Utils::StrongMemoize

      MAX_PACKAGES_COUNT = 500

      def initialize(current_user, params, project: nil)
        @current_user = current_user
        @name, @version, @username, _ = params[:query].to_s.split(%r{[@/]})
        @project = project
      end

      def execute
        return ::Packages::Conan::Package.none unless name.present?

        packages
      end

      private

      attr_reader :current_user, :name, :project, :version, :username

      def packages
        matching_packages = base
        .installable
        .preload_conan_metadatum
        .with_name_like(name)
        matching_packages = matching_packages.with_version(version) if version.present?
        matching_packages.limit_recent(MAX_PACKAGES_COUNT)
      end

      def base
        ::Packages::Conan::Package.for_projects(project || projects_available_in_current_context)
      end

      def projects_available_in_current_context
        return ::Project.public_or_visible_to_user(current_user, ::Gitlab::Access::REPORTER) unless username.present?
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
    end
  end
end
