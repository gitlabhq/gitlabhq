# frozen_string_literal: true

module Gitlab
  module LegacyGithubImport
    class BaseFormatter
      attr_reader :client, :formatter, :project, :raw_data

      def initialize(project, raw_data, client = nil)
        @project = project
        @raw_data = raw_data
        @client = client
        @formatter = Gitlab::ImportFormatter.new
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def create!
        association = project.public_send(project_association) # rubocop:disable GitlabSecurity/PublicSend

        association.find_or_create_by!(find_condition) do |record|
          record.attributes = attributes
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def url
        raw_data[:url] || ''
      end

      def imported_from
        return ::Import::SOURCE_GITEA if project.gitea_import?
        return ::Import::SOURCE_GITHUB if project.github_import?

        ::Import::SOURCE_NONE
      end
    end
  end
end
