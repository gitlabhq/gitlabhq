# frozen_string_literal: true

module Gitlab
  module GithubImport
    class Settings
      OPTIONAL_STAGES = {
        single_endpoint_notes_import: {
          label: 'Use alternative comments import method',
          selected: false,
          details: <<-TEXT.split("\n").map(&:strip).join(' ')
            The default method can skip some comments in large projects because of limitations of the GitHub API.
          TEXT
        },
        attachments_import: {
          label: 'Import Markdown attachments (links)',
          selected: false,
          details: <<-TEXT.split("\n").map(&:strip).join(' ')
            Import Markdown attachments (links) from repository comments, release posts, issue descriptions,
            and pull request descriptions. These can include images, text, or binary attachments.
            If not imported, links in Markdown to attachments break after you remove the attachments from GitHub.
          TEXT
        },
        collaborators_import: {
          label: 'Import collaborators',
          selected: true,
          details: <<-TEXT.split("\n").map(&:strip).join(' ')
            Import direct repository collaborators who are not outside collaborators.
            Imported collaborators who aren't members of the group you imported the project into consume seats on your GitLab instance.
          TEXT
        }
      }.freeze

      def self.stages_array(_current_user)
        OPTIONAL_STAGES.map do |stage_name, data|
          {
            name: stage_name.to_s,
            label: s_(format("GitHubImport|%{text}", text: data[:label])),
            selected: data[:selected],
            details: s_(format("GitHubImport|%{text}", text: data[:details]))
          }
        end
      end

      def initialize(project)
        @project = project
      end

      def write(user_settings)
        user_settings = user_settings.to_h.with_indifferent_access

        optional_stages = fetch_stages_from_params(user_settings[:optional_stages])

        import_data = project.build_or_assign_import_data(
          data: {
            optional_stages: optional_stages,
            timeout_strategy: user_settings[:timeout_strategy],
            user_contribution_mapping_enabled: user_contribution_mapping_enabled?,
            pagination_limit: user_settings[:pagination_limit]
          },
          credentials: project.import_data&.credentials
        )

        import_data.save!
      end

      def enabled?(stage_name)
        project.import_data&.data&.dig('optional_stages', stage_name.to_s) || false
      end

      def disabled?(stage_name)
        !enabled?(stage_name)
      end

      def user_mapping_enabled?
        project.import_data&.data&.dig('user_contribution_mapping_enabled') || false
      end

      private

      attr_reader :project

      def fetch_stages_from_params(user_settings)
        user_settings = user_settings.to_h.with_indifferent_access

        OPTIONAL_STAGES.keys.to_h do |stage_name|
          enabled = Gitlab::Utils.to_boolean(user_settings[stage_name], default: false)
          [stage_name, enabled]
        end
      end

      def user_contribution_mapping_enabled?
        creator_user_actor = User.actor_from_id(project.creator_id)

        return false unless Feature.enabled?(:importer_user_mapping, creator_user_actor)

        flag_by_type = case project.import_type&.to_sym
                       when ::Import::SOURCE_GITHUB
                         Feature.enabled?(:github_user_mapping, creator_user_actor)
                       when ::Import::SOURCE_GITEA
                         Feature.enabled?(:gitea_user_mapping, creator_user_actor)
                       end

        !!flag_by_type
      end
    end
  end
end
