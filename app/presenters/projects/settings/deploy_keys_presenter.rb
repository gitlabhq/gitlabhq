module Projects
  module Settings
    class DeployKeysPresenter < Gitlab::View::Presenter::Simple
      presents :project
      delegate :size, to: :enabled_keys, prefix: true
      delegate :size, to: :available_project_keys, prefix: true
      delegate :size, to: :available_public_keys, prefix: true

      def new_key
        @key ||= DeployKey.new.tap { |dk| dk.deploy_keys_projects.build }
      end

      def enabled_keys
        @enabled_keys ||= project.deploy_keys.includes(:projects)
      end

      def any_keys_enabled?
        enabled_keys.any?
      end

      def available_keys
        @available_keys ||= current_user.accessible_deploy_keys - enabled_keys
      end

      def available_project_keys
        @available_project_keys ||= current_user.project_deploy_keys.includes(:projects) - enabled_keys
      end

      def key_available?(deploy_key)
        available_keys.include?(deploy_key)
      end

      def available_public_keys
        return @available_public_keys if defined?(@available_public_keys)

        @available_public_keys ||= DeployKey.are_public.includes(:projects) - enabled_keys

        # Public keys that are already used by another accessible project are already
        # in @available_project_keys.
        @available_public_keys -= available_project_keys
      end

      def as_json
        serializer = DeployKeySerializer.new
        opts = { user: current_user }

        {
          enabled_keys: serializer.represent(enabled_keys, opts),
          available_project_keys: serializer.represent(available_project_keys, opts),
          public_keys: serializer.represent(available_public_keys, opts)
        }
      end

      def to_partial_path
        'projects/deploy_keys/index'
      end

      def form_partial_path
        'projects/deploy_keys/form'
      end
    end
  end
end
