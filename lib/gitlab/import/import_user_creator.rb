# frozen_string_literal: true

module Gitlab
  module Import
    class ImportUserCreator
      include Gitlab::Utils::StrongMemoize

      NoRootGroupError = Class.new(StandardError)

      attr_reader :portable

      def initialize(portable:)
        @portable = portable
      end

      def execute
        raise NoRootGroupError, 'Portable has no root group' unless root_ancestor

        return import_user if import_user

        User.transaction do
          user = create_user
          create_namespace_import_user(user)
          user
        end
      rescue ActiveRecord::RecordNotUnique => e
        ::Import::Framework::Logger.warn(
          message: 'Failed to create namespace_import_user',
          error: e.message
        )

        # Import user already exists, try finding it again
        import_user
      end

      private

      def create_user
        User.create!(
          user_type: :import_user,
          name: 'Import User',
          username: username_and_email_generator.username,
          email: username_and_email_generator.email
        ) do |u|
          u.assign_personal_namespace(root_ancestor.organization)
        end
      end

      def create_namespace_import_user(user)
        ::Import::NamespaceImportUser.create!(
          user_id: user.id,
          namespace_id: root_ancestor.id
        )
      end

      def username_and_email_generator
        Gitlab::Utils::UsernameAndEmailGenerator.new(
          username_prefix: username_prefix,
          email_domain: "noreply.#{Gitlab.config.gitlab.host}"
        )
      end
      strong_memoize_attr :username_and_email_generator

      def import_user
        root_ancestor.import_user
      end

      def root_ancestor
        portable.root_ancestor
      end

      def username_prefix
        "import_user_namespace_#{root_ancestor.id}"
      end
    end
  end
end
