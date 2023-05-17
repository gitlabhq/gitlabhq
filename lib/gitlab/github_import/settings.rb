# frozen_string_literal: true

module Gitlab
  module GithubImport
    class Settings
      OPTIONAL_STAGES = {
        single_endpoint_issue_events_import: {
          label: 'Import issue and pull request events',
          selected: false,
          details: <<-TEXT.split("\n").map(&:strip).join(' ')
            For example, opened or closed, renamed, and labeled or unlabeled.
            Time required to import these events depends on how many issues or pull requests your project has.
          TEXT
        },
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

      def self.stages_array
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

        optional_stages = fetch_stages_from_params(user_settings)
        import_data = project.create_or_update_import_data(data: { optional_stages: optional_stages })
        import_data.save!
      end

      def enabled?(stage_name)
        project.import_data&.data&.dig('optional_stages', stage_name.to_s) || false
      end

      def disabled?(stage_name)
        !enabled?(stage_name)
      end

      private

      attr_reader :project

      def fetch_stages_from_params(user_settings)
        OPTIONAL_STAGES.keys.to_h do |stage_name|
          enabled = Gitlab::Utils.to_boolean(user_settings[stage_name], default: false)
          [stage_name, enabled]
        end
      end
    end
  end
end
