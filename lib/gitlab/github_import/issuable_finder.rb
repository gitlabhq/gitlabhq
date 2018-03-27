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
      CACHE_KEY = 'github-import/issuable-finder/%{project}/%{type}/%{iid}'.freeze

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
        val = Caching.read(cache_key)

        val.to_i if val.present?
      end

      # Associates the given database ID with the current object.
      #
      # database_id - The ID of the corresponding database row.
      def cache_database_id(database_id)
        Caching.write(cache_key, database_id)
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
        else
          raise(
            TypeError,
            "Instances of #{object.class} are not supported"
          )
        end
      end
    end
  end
end
