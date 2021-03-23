# frozen_string_literal: true

module Projects
  module Settings
    class DeployKeysPresenter < Gitlab::View::Presenter::Simple
      include Gitlab::Utils::StrongMemoize

      presents :project
      delegate :size, to: :enabled_keys, prefix: true
      delegate :size, to: :available_project_keys, prefix: true
      delegate :size, to: :available_public_keys, prefix: true

      def new_key
        @key ||= DeployKey.new.tap { |dk| dk.deploy_keys_projects.build }
      end

      # It includes:
      # - The deploy keys enabled in the project.
      def enabled_keys
        strong_memoize(:enabled_keys) do
          project.deploy_keys.with_projects
        end
      end

      # NOTE: This method is redundant. Use `available_project_keys` and `available_public_keys` instead.
      # It includes:
      # - Enabled deploy keys in projects that can be accessed by the user.
      # - Instance-level public deploy keys.
      # It excludes:
      # - The deploy keys enabled in the project.
      def available_keys
        strong_memoize(:available_keys) do
          current_user
            .accessible_deploy_keys
            .id_not_in(enabled_keys.select(:id))
            .with_projects
        end
      end

      # It includes:
      # - Enabled deploy keys in projects that can be accessed by the user.
      # It excludes:
      # - The deploy keys enabled in the project
      def available_project_keys
        if Feature.enabled?(:optimize_deploy_keys_presenter, project, default_enabled: :yaml)
          strong_memoize(:available_project_keys) do
            current_user.project_deploy_keys.with_projects - enabled_keys
          end
        else
          strong_memoize(:legacy_available_project_keys) do
            current_user
              .project_deploy_keys
              .id_not_in(enabled_keys.select(:id))
              .with_projects
          end
        end
      end

      # It includes:
      # - Instance-level public deploy keys.
      # It excludes:
      # - The deploy keys enabled in the project.
      def available_public_keys
        if Feature.enabled?(:optimize_deploy_keys_presenter, project, default_enabled: :yaml)
          strong_memoize(:available_public_keys) do
            DeployKey.are_public.with_projects - enabled_keys
          end
        else
          strong_memoize(:legacy_available_public_keys) do
            # This also excludes "Enabled deploy keys in projects that can be accessed by the user".
            # However, this means we are filtering out a public key that enabled
            # in the other project, which should be also available for this project.
            # We should expose the public keys that has not been enabled on the project yet.
            DeployKey
              .are_public
              .id_not_in(enabled_keys.select(:id))
              .id_not_in(available_project_keys.select(:id))
              .with_projects
          end
        end
      end

      def as_json
        serializer = DeployKeySerializer.new # rubocop: disable CodeReuse/Serializer
        opts = { user: current_user, project: project, readable_project_ids: readable_project_ids }

        {
          enabled_keys: serializer.represent(enabled_keys, opts),
          available_project_keys: serializer.represent(available_project_keys, opts),
          public_keys: serializer.represent(available_public_keys, opts)
        }
      end

      def to_partial_path
        '../../shared/deploy_keys/index'
      end

      def form_partial_path
        'shared/deploy_keys/project_group_form'
      end

      private

      # Caching all readable project ids for the user that are associated with the queried deploy keys
      def readable_project_ids
        strong_memoize(:readable_projects_by_id) do
          Set.new(user_readable_project_ids)
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def user_readable_project_ids
        project_ids = if Feature.enabled?(:optimize_deploy_keys_presenter, project, default_enabled: :yaml)
                        (available_project_keys + available_public_keys)
                          .flat_map { |deploy_key| deploy_key.deploy_keys_projects.map(&:project_id) }
                          .compact
                          .uniq
                      else
                        (available_keys + available_project_keys + available_public_keys)
                          .flat_map { |deploy_key| deploy_key.deploy_keys_projects.map(&:project_id) }
                          .compact
                          .uniq
                      end

        current_user.authorized_projects(Gitlab::Access::GUEST).id_in(project_ids).pluck(:id)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
