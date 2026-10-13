# frozen_string_literal: true

module Gitlab
  module GithubImport
    # Class that can be used for finding a GitLab user ID based on a GitHub user
    # ID or username.
    #
    # Any found user IDs are cached in Redis to reduce the number of SQL queries
    # executed over time. Valid keys are refreshed upon access so frequently
    # used keys stick around.
    #
    # Lookups are cached even if no ID was found to remove the need for querying
    # the database when most queries are not going to return results anyway.
    class UserFinder
      include Gitlab::ExclusiveLeaseHelpers
      include Gitlab::Utils::StrongMemoize

      attr_reader :project, :client

      SOURCE_NAME_CACHE_KEY = 'github-import/user-finder/%{project}/source-name/%{username}'

      # project - An instance of `Project`
      # client - An instance of `Gitlab::GithubImport::Client`
      def initialize(project, client)
        @project = project
        @client = client
      end

      # Returns the GitLab user ID of an object's author.
      #
      # If the object has no author ID we'll use the ID of the GitLab ghost
      # user.
      # object - An instance of `Hash` or a `Github::Representer`
      def author_id_for(object, author_key: :author)
        user_info = case author_key
                    when :actor
                      object[:actor]
                    when :review_requester
                      object[:review_requester]
                    else
                      object ? object[:author] : nil
                    end

        # TODO when improved user mapping is released we can refactor everything below to just
        # user_id_for(user_info)
        id = user_id_for(user_info, ghost: true)

        if id
          [id, true]
        else
          [project.creator_id, false]
        end
      end

      # Returns the GitLab user ID for a GitHub user. Can return nil if `ghost` is `false`.
      # The `ghost: false` argument is used to avoid assigning ghost users as assignees or reviewers.
      #
      # @param user [Gitlab::GithubImport::Representation::User, Hash]
      # @param ghost [Boolean] Determines what to do if user is nil or is the GitHub ghost.
      #   If `true`, ID of the GitLab ghost is returned.
      #   If `false`, nil is returned.
      # @return [Integer, NilClass]
      def user_id_for(user, ghost: true)
        # user[:login] == 'ghost' here refers to the Github username
        if user.nil? || user[:login].nil? || user[:login] == 'ghost'
          return ghost ? GithubImport.ghost_user_id(project.organization_id) : nil
        end

        return project.root_ancestor.owner_id if map_to_personal_namespace_owner?

        source_user(user).mapped_user_id
      end

      # Returns the GitLab user ID from placeholder or reassigned_to user.
      def source_user(user)
        source_user = source_user_mapper.find_source_user(user[:id])

        return source_user if source_user

        source_user_mapper.find_or_create_source_user(
          source_name: fetch_source_name_from_github(user[:login]),
          source_username: user[:login],
          source_user_identifier: user[:id]
        )
      end

      # Returns true if GitLab user has accepted their reassignment status
      def source_user_accepted?(user)
        return true if map_to_personal_namespace_owner?

        source_user(user).accepted_status?
      end

      # Retrieves the name of the user associated with a specified GitHub username.
      #
      # To prevent multiple concurrent requests for the same user, a exclusive lock is used.
      # The name is cached to avoid multiple calls to GitHub.
      #
      # @param [String] username GitHub username
      # @return [String] name of the user
      def fetch_source_name_from_github(username)
        in_lock(lease_key(username), sleep_sec: 0.2.seconds, retries: 30) do |retried|
          if retried
            source_name = read_source_name_from_cache(username)

            next source_name if source_name.present?
          end

          begin
            user = client.user(username)
            source_name = user.fetch(:name, username)
          rescue ::Octokit::NotFound => error
            log("GitHub user not found. #{error.message}", username: username)

            source_name = username
          end

          cache_source_name(username, source_name)

          source_name
        end
      end

      private

      def lease_key(username)
        "gitlab:github_import:user_finder:#{username}"
      end

      # Reads source name from internal cache for the given username
      #
      # @param [String] username The username of the GitHub user.
      # @return [String|nil] Return the cached source name or nil
      def read_source_name_from_cache(username)
        Gitlab::Cache::Import::Caching.read(source_name_cache_key(username))
      end

      # Caches the source name associated to the username
      #
      # @param [String] username The username of the GitHub user.
      # @param [String] source_name The source_name to value to be cached.
      def cache_source_name(username, source_name)
        Gitlab::Cache::Import::Caching.write(source_name_cache_key(username), source_name)
      end

      def source_name_cache_key(username)
        format(SOURCE_NAME_CACHE_KEY, project: project.id, username: username)
      end

      def log(message, username: nil)
        Logger.info(
          project_id: project.id,
          Labkit::Fields::GL_ORGANIZATION_ID => project.organization_id,
          class: self.class.name,
          username: username,
          message: message
        )
      end

      def source_user_mapper
        ::Gitlab::Import::SourceUserMapper.new(
          namespace: project.root_ancestor,
          source_hostname: project.safe_import_url,
          import_type: ::Import::SOURCE_GITHUB
        )
      end
      strong_memoize_attr :source_user_mapper

      def map_to_personal_namespace_owner?
        project.root_ancestor.user_namespace?
      end
    end
  end
end
