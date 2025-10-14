# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class LabelLinksImporter
        attr_reader :issue, :project, :client, :label_finder

        # issue - An instance of `Gitlab::GithubImport::Representation::Issue`
        # project - An instance of `Project`
        # client - An instance of `Gitlab::GithubImport::Client`
        def initialize(issue, project, client)
          @issue = issue
          @project = project
          @client = client
          @label_finder = LabelFinder.new(project)
        end

        def execute
          create_labels
        end

        def create_labels
          time = Time.zone.now
          items = []
          target_id = find_target_id

          return if target_id.blank?

          issue.label_names.each do |label_name|
            # Although unlikely it's technically possible for an issue to be
            # given a label that was created and assigned after we imported all
            # the project's labels.
            next unless (label_id = label_finder.id_for(label_name))

            label_link = LabelLink.new(
              label_id: label_id,
              target_id: target_id,
              target_type: issue.issuable_type,
              created_at: time,
              updated_at: time
            )
            begin
              label_link.validate!
            rescue ActiveRecord::RecordInvalid => e
              track_error(e, label_link)
              next
            end

            items << label_link
          end

          LabelLink.bulk_insert!(items, validate: false)
        end

        def find_target_id
          GithubImport::IssuableFinder.new(project, issue).database_id
        end

        private

        def track_error(exception, label_link)
          Gitlab::Import::ImportFailureService.track(
            project_id: project.id,
            error_source: self.class.name,
            exception: exception,
            fail_import: false,
            external_identifiers: label_link.attributes.symbolize_keys.except(:id)
          )
        end
      end
    end
  end
end
