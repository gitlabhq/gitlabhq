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
      attr_reader :project, :client

      # The base cache key to use for caching user IDs for a given GitHub user
      # ID.
      ID_CACHE_KEY = 'github-import/user-finder/user-id/%s'

      # The base cache key to use for caching user IDs for a given GitHub email
      # address.
      ID_FOR_EMAIL_CACHE_KEY =
        'github-import/user-finder/id-for-email/%s'

      # The base cache key to use for caching the Email addresses of GitHub
      # usernames.
      EMAIL_FOR_USERNAME_CACHE_KEY =
        'github-import/user-finder/email-for-username/%s'

      # The base cache key to use for caching inexistence of GitHub usernames.
      INEXISTENCE_OF_GITHUB_USERNAME_CACHE_KEY = 'github-import/user-finder/inexistence-of-username/%s'

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
                    when :assignee
                      object[:assignee]
                    when :requested_reviewer
                      object[:requested_reviewer]
                    when :review_requester
                      object[:review_requester]
                    else
                      object ? object[:author] : nil
                    end

        id = user_info ? user_id_for(user_info) : GithubImport.ghost_user_id

        if id
          [id, true]
        else
          [project.creator_id, false]
        end
      end

      # Returns the GitLab user ID of an issuable's assignee.
      def assignee_id_for(issuable)
        user_id_for(issuable[:assignee]) if issuable[:assignee]
      end

      # Returns the GitLab user ID for a GitHub user.
      #
      # user - An instance of `Gitlab::GithubImport::Representation::User` or `Hash`.
      def user_id_for(user)
        find(user[:id], user[:login]) if user.present?
      end

      # Returns the GitLab ID for the given GitHub ID or username.
      #
      # id - The ID of the GitHub user.
      # username - The username of the GitHub user.
      def find(id, username)
        email = email_for_github_username(username)
        cached, found_id = find_from_cache(id, email)

        return found_id if found_id

        # We only want to query the database if necessary. If previous lookups
        # didn't yield a user ID we won't query the database again until the
        # keys expire.
        find_id_from_database(id, email) unless cached
      end

      # Finds a user ID from the cache for a given GitHub ID or Email.
      def find_from_cache(id, email = nil)
        id_exists, id_for_github_id = cached_id_for_github_id(id)

        return [id_exists, id_for_github_id] if id_for_github_id

        # Just in case no Email address could be retrieved (for whatever reason)
        return [false] unless email

        cached_id_for_github_email(email)
      end

      # Finds a GitLab user ID from the database for a given GitHub user ID or
      # Email.
      def find_id_from_database(id, email)
        id_for_github_id(id) || id_for_github_email(email)
      end

      def email_for_github_username(username)
        cache_key = EMAIL_FOR_USERNAME_CACHE_KEY % username
        email = Gitlab::Cache::Import::Caching.read(cache_key)

        if email.blank? && !github_username_inexists?(username)
          user = client.user(username)
          email = Gitlab::Cache::Import::Caching.write(cache_key, user[:email], timeout: timeout(user[:email])) if user
        end

        email
      rescue ::Octokit::NotFound
        cache_github_username_inexistence(username)
        nil
      end

      def cached_id_for_github_id(id)
        read_id_from_cache(ID_CACHE_KEY % id)
      end

      def cached_id_for_github_email(email)
        read_id_from_cache(ID_FOR_EMAIL_CACHE_KEY % email)
      end

      # If importing from github.com, queries and caches the GitLab user ID for
      # a GitHub user ID, if one was found.
      #
      # When importing from Github Enterprise, do not query user by Github ID
      # since we only have users' Github ID from github.com.
      def id_for_github_id(id)
        gitlab_id =
          if project.github_enterprise_import?
            nil
          else
            query_id_for_github_id(id)
          end

        Gitlab::Cache::Import::Caching.write(ID_CACHE_KEY % id, gitlab_id)
      end

      # Queries and caches the GitLab user ID for a GitHub email, if one was
      # found.
      def id_for_github_email(email)
        gitlab_id = query_id_for_github_email(email) || nil

        Gitlab::Cache::Import::Caching.write(ID_FOR_EMAIL_CACHE_KEY % email, gitlab_id)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def query_id_for_github_id(id)
        User.by_provider_and_extern_uid(:github, id).select(:id).first&.id
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def query_id_for_github_email(email)
        User.by_any_email(email).pick(:id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Reads an ID from the cache.
      #
      # The return value is an Array with two values:
      #
      # 1. A boolean indicating if the key was present or not.
      # 2. The ID as an Integer, or nil in case no ID could be found.
      def read_id_from_cache(key)
        value = Gitlab::Cache::Import::Caching.read(key)
        exists = !value.nil?
        number = value.to_i

        # The cache key may be empty to indicate a previously looked up user for
        # which we couldn't find an ID.
        [exists, number > 0 ? number : nil]
      end

      private

      def timeout(email)
        if email
          Gitlab::Cache::Import::Caching::TIMEOUT
        else
          Gitlab::Cache::Import::Caching::SHORTER_TIMEOUT
        end
      end

      def github_username_inexists?(username)
        cache_key = INEXISTENCE_OF_GITHUB_USERNAME_CACHE_KEY % username

        Gitlab::Cache::Import::Caching.read(cache_key) == 'true'
      end

      def cache_github_username_inexistence(username)
        cache_key = INEXISTENCE_OF_GITHUB_USERNAME_CACHE_KEY % username

        Gitlab::Cache::Import::Caching.write(cache_key, true)
      end
    end
  end
end
