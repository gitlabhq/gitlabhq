# frozen_string_literal: true

module Packages
  module Conan
    class SinglePackageSearchService # rubocop:disable Search/NamespacedClass
      include Gitlab::Utils::StrongMemoize

      def initialize(query, current_user)
        @name, @version, @username, _ = query.split(%r{[@/]})
        @current_user = current_user
      end

      def execute
        ServiceResponse.success(payload: { results: search_results })
      end

      private

      attr_reader :name, :version, :username, :current_user

      def search_results
        return [] unless can_access_project_package?

        [package&.conan_recipe].compact
      end

      def package
        project
          .packages
          .with_name(name)
          .with_version(version)
          .order_created
          .last
      end

      def project
        Project.find_by_full_path(full_path)
      end
      strong_memoize_attr :project

      def full_path
        ::Packages::Conan::Metadatum.full_path_from(package_username: username)
      end

      def can_access_project_package?
        Ability.allowed?(current_user, :read_package, project.try(:packages_policy_subject))
      end
    end
  end
end
