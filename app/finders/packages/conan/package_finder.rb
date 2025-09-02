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
        @ignorecase = params[:ignorecase]
      end

      def execute
        return ::Packages::Conan::Package.none unless name.present?
        return ::Packages::Conan::Package.none if name == SQL_WILDCARD && version == SQL_WILDCARD
        return ::Packages::Conan::Package.none unless project || project_from_path

        packages
      end

      private

      attr_reader :current_user, :name, :project, :version, :username, :ignorecase

      def sanitize_sql(query)
        sanitize_sql_like(query).tr(WILDCARD, SQL_WILDCARD) unless query.nil?
      end

      def packages
        packages = by_name(base.installable.preload_conan_metadatum)
        packages = by_version(packages) if version.present?
        packages.limit_recent(MAX_PACKAGES_COUNT)
      end

      def by_name(packages)
        if ignorecase == false
          packages.with_name_like(name, case_sensitive: true)
        else
          packages.with_name_like(name)
        end
      end

      def by_version(packages)
        if version.include?(SQL_WILDCARD)
          packages.with_version_like(version)
        else
          packages.with_version(version)
        end
      end

      def base
        ::Packages::Conan::Package.for_projects(project || project_from_path)
      end

      def project_from_path
        return unless full_path

        project = Project.find_by_full_path(full_path)

        return unless Ability.allowed?(current_user, :read_package, project.packages_policy_subject)

        project
      end
      strong_memoize_attr :project_from_path

      def full_path
        return unless username

        ::Packages::Conan::Metadatum.full_path_from(package_username: username)
      end
      strong_memoize_attr :full_path
    end
  end
end
