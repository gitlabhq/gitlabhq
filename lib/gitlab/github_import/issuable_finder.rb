# frozen_string_literal: true

module Gitlab
  module GithubImport
    # IssuableFinder can be used for caching and retrieving database IDs for
    # issuable objects such as issues and pull requests. By caching these IDs we
    # remove the need for running a lot of database queries when importing
    # GitHub projects.
    class IssuableFinder
      attr_reader :project, :object

      # The base cache key to use for storing/retrieving issuable IDs.
      CACHE_KEY = 'github-import/issuable-finder/%{project}/%{type}/%{iid}'
      CACHE_OBJECT_NOT_FOUND = -1

      # project - An instance of `Project`.
      # object - The object to look up or set a database ID for.
      def initialize(project, object)
        @project = project
        @object = object
      end

      # Returns the database ID for the object.
      #
      # This method will return `nil` if no ID could be found.
      def database_id
        val = Gitlab::Cache::Import::Caching.read_integer(cache_key, timeout: timeout)

        return if val == CACHE_OBJECT_NOT_FOUND
        return val if val.present?

        object_id = cache_key_type.safe_constantize&.find_by(project_id: project.id, iid: cache_key_iid)&.id ||
          CACHE_OBJECT_NOT_FOUND

        cache_database_id(object_id)
        object_id == CACHE_OBJECT_NOT_FOUND ? nil : object_id
      end

      # Associates the given database ID with the current object.
      #
      # database_id - The ID of the corresponding database row.
      def cache_database_id(database_id)
        Gitlab::Cache::Import::Caching.write(cache_key, database_id, timeout: timeout)
      end

      private

      def cache_key
        CACHE_KEY % {
          project: project.id,
          type: cache_key_type,
          iid: cache_key_iid
        }
      end

      # Returns the identifier to use for cache keys.
      #
      # For issues and pull requests this will be "Issue" or "MergeRequest"
      # respectively. For diff notes this will return "MergeRequest", for
      # regular notes it will either return "Issue" or "MergeRequest" depending
      # on what type of object the note belongs to.
      def cache_key_type
        if object.respond_to?(:issuable_type)
          object.issuable_type
        elsif object.respond_to?(:noteable_type)
          object.noteable_type
        else
          raise(
            TypeError,
            "Instances of #{object.class} are not supported"
          )
        end
      end

      def cache_key_iid
        if object.respond_to?(:noteable_id)
          object.noteable_id
        elsif object.respond_to?(:iid)
          object.iid
        elsif object.respond_to?(:issuable_id)
          object.issuable_id
        else
          raise(
            TypeError,
            "Instances of #{object.class} are not supported"
          )
        end
      end

      def timeout
        if import_settings.enabled?(:single_endpoint_notes_import)
          Gitlab::Cache::Import::Caching::LONGER_TIMEOUT
        else
          Gitlab::Cache::Import::Caching::TIMEOUT
        end
      end

      def import_settings
        ::Gitlab::GithubImport::Settings.new(project)
      end
    end
  end
end
