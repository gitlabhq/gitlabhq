# frozen_string_literal: true

module Gitlab
  module Repositories
    class DesignManagementRepository < Gitlab::Repositories::RepoType
      include Singleton
      extend Gitlab::Utils::Override

      override :name
      def name = :design

      override :design
      def suffix = :design

      override :access_checker_class
      def access_checker_class = ::Gitlab::GitAccessDesign

      override :guest_read_ability
      def guest_read_ability = :download_code

      override :container_class
      def container_class = DesignManagement::Repository

      override :project_for
      def project_for(design_management_repository)
        design_management_repository&.project
      end

      private

      override :repository_resolver
      def repository_resolver(design_management_repository)
        design_management_repository.repository
      end
    end
  end
end
