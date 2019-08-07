# frozen_string_literal: true

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
        project.deploy_keys
      end

      def available_keys
        current_user
          .accessible_deploy_keys
          .id_not_in(enabled_keys.select(:id))
          .with_projects
      end

      def available_project_keys
        current_user
          .project_deploy_keys
          .id_not_in(enabled_keys.select(:id))
          .with_projects
      end

      def available_public_keys
        DeployKey
          .are_public
          .id_not_in(enabled_keys.select(:id))
          .id_not_in(available_project_keys.select(:id))
          .with_projects
      end

      def as_json
        serializer = DeployKeySerializer.new # rubocop: disable CodeReuse/Serializer
        opts = { user: current_user }

        {
          enabled_keys: serializer.represent(enabled_keys.with_projects, opts),
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
