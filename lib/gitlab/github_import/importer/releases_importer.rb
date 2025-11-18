# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class ReleasesImporter
        include BulkImporting
        include ::Import::PlaceholderReferences::Pusher

        # rubocop: disable CodeReuse/ActiveRecord
        def existing_tags
          @existing_tags ||= project.releases.pluck(:tag).to_set
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def github_users
          @github_users ||= []
        end

        # Note: if you're going to replace `legacy_bulk_insert` with something that triggers callback
        # to generate HTML version - you also need to regenerate it in
        # Gitlab::GithubImport::Importer::NoteAttachmentsImporter.
        def execute
          rows, validation_errors = build_releases

          inserted_ids = bulk_insert(rows)

          inserted_ids.zip(github_users).each do |id, user|
            # `id` is the GitLab Release ID we just inserted.
            # `user` is the GitHub user object.
            push_references_by_ids(project, [id], Release, :author_id, user[:id])
          end

          bulk_insert_failures(validation_errors) if validation_errors.any?
        end

        def build_releases
          build_database_rows(each_release)
        end

        def already_imported?(release)
          existing_tags.include?(release[:tag_name]) || release[:tag_name].nil?
        end

        def build_attributes(release)
          existing_tags.add(release[:tag_name])
          # when release author is nil (deleted on github) we assign the ghost user
          github_users.push(map_github_user_info(release))

          {
            name: release[:name],
            tag: release[:tag_name],
            author_id: fetch_author_id(release),
            description: description_for(release),
            created_at: release[:created_at],
            updated_at: release[:created_at],
            # Draft releases will have a null published_at
            released_at: release[:published_at] || Time.current,
            project_id: project.id
          }
        end

        def map_github_user_info(release)
          {
            id: release.dig(:author, :id) || Gitlab::GithubImport.ghost_user_id(project.organization_id),
            login: release.dig(:author, :login) || 'ghost'
          }
        end

        def each_release
          client.releases(project.import_source)
        end

        def description_for(release)
          description = release[:body].presence || "Release for tag #{release[:tag_name]}"
          user = map_github_user_info(release)

          MarkdownText.format(description, user, user[:id], project: project, client: client)
        end

        def object_type
          :release
        end

        private

        def fetch_author_id(release)
          author_id, _author_found = user_finder.author_id_for(release)

          author_id
        end

        def user_finder
          @user_finder ||= GithubImport::UserFinder.new(project, client)
        end

        def model
          Release
        end

        def github_identifiers(release)
          {
            tag: release[:tag_name],
            object_type: object_type
          }
        end
      end
    end
  end
end
