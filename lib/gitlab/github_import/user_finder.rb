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

      attr_reader :project, :client

      # The base cache key to use for caching user IDs for a given GitHub user ID.
      ID_CACHE_KEY = 'github-import/user-finder/user-id/%s'

      # The base cache key to use for caching user IDs for a given GitHub email address.
      ID_FOR_EMAIL_CACHE_KEY = 'github-import/user-finder/id-for-email/%s'

      # The base cache key to use for caching the Email addresses of GitHub usernames.
      EMAIL_FOR_USERNAME_CACHE_KEY = 'github-import/user-finder/email-for-username/%s'

      # The base cache key to use for caching the user ETAG response headers
      USERNAME_ETAG_CACHE_KEY = 'github-import/user-finder/user-etag/%s'

      # The base cache key to store whether an email has been fetched for a project
      EMAIL_FETCHED_FOR_PROJECT_CACHE_KEY = 'github-import/user-finder/%{project}/email-fetched/%{username}'

      EMAIL_API_CALL_LOGGING_MESSAGE = {
        true => 'Fetching email from GitHub with ETAG header',
        false => 'Fetching email from GitHub'
      }.freeze

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

      # Find the public email of a given username in GitHub.
      # The email is cached to avoid multiple calls to GitHub. The cache is shared among all projects.
      # If the email was not found, a blank email is cached.
      # If the email is blank, we attempt to fetch it from GitHub using an ETAG request once for every project.

      # @param username [String] The username of the GitHub user.
      #
      # @return [String] If public email is found
      # @return [Nil] If public email or username does not exist
      def email_for_github_username(username)
        email = read_email_from_cache(username)

        if email.blank? && !email_fetched_for_project?(username)
          feature_flag_in_lock(lease_key(username), sleep_sec: 0.2.seconds, retries: 30) do |retried|
            # when retried, check the cache again as the other process that had the lease may have fetched the email
            if retried
              email = read_email_from_cache(username)

              # early return if the other process fetched a non-empty email. If the email is empty, we'll attempt to
              # fetch it again in the lines below, but using the ETAG cached by the other process which won't count to
              # the rate limit.
              next email if email.present?
            end

            # If an ETAG is available, make an API call with the ETAG.
            # Only make a rate-limited API call if the ETAG is not available and the email is nil.
            etag = read_etag_from_cache(username)
            email = fetch_email_from_github(username, etag: etag) || email

            cache_email!(username, email)
            cache_etag!(username) if email.blank? && etag.nil?

            # If a non-blank email is cached, we don't need the ETAG or project check caches.
            # Otherwise, indicate that the project has been checked.
            if email.present?
              clear_caches!(username)
            else
              set_project_as_checked!(username)
            end
          end
        end

        email.presence
      rescue ::Octokit::NotFound
        cache_email!(username, '')
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

      def lease_key(username)
        "gitlab:github_import:user_finder:#{username}"
      end

      # Retrieves the email associated with the given username from the cache.
      #
      # The return value can be an email, an empty string, or nil.
      #
      # If an empty string is returned, it indicates that the user's email was fetched but not set on GitHub.
      # If nil is returned, it indicates that the user's email wasn't fetched or the cache has expired.
      # If an email is returned, it means the user has a public email set, and it has been successfully cached.
      def read_email_from_cache(username)
        Gitlab::Cache::Import::Caching.read(email_cache_key(username))
      end

      def read_etag_from_cache(username)
        Gitlab::Cache::Import::Caching.read(etag_cache_key(username))
      end

      def email_fetched_for_project?(username)
        email_fetched_for_project_cache_key = email_fetched_for_project_cache_key(username)
        Gitlab::Cache::Import::Caching.read(email_fetched_for_project_cache_key)
      end

      def fetch_email_from_github(username, etag: nil)
        log(EMAIL_API_CALL_LOGGING_MESSAGE[etag.present?], username: username)

        # Only make a rate-limited API call if the ETAG is not available })
        user = client.user(username, { headers: { 'If-None-Match' => etag }.compact })
        user[:email] || '' if user
      end

      # Caches the email associated to the username
      #
      # An empty email is cached when the user email isn't set on GitHub.
      # This is done to prevent UserFinder from fetching the user's email again when the user's email isn't set on
      # GitHub
      def cache_email!(username, email)
        return unless email

        Gitlab::Cache::Import::Caching.write(email_cache_key(username), email)
      end

      def cache_etag!(username)
        return unless client.octokit.last_response

        etag = client.octokit.last_response.headers[:etag]
        Gitlab::Cache::Import::Caching.write(etag_cache_key(username), etag)
      end

      def set_project_as_checked!(username)
        Gitlab::Cache::Import::Caching.write(email_fetched_for_project_cache_key(username), 1)
      end

      def clear_caches!(username)
        Gitlab::Cache::Import::Caching.expire(etag_cache_key(username), 0)
        Gitlab::Cache::Import::Caching.expire(email_fetched_for_project_cache_key(username), 0)
      end

      def email_cache_key(username)
        EMAIL_FOR_USERNAME_CACHE_KEY % username
      end

      def etag_cache_key(username)
        USERNAME_ETAG_CACHE_KEY % username
      end

      def email_fetched_for_project_cache_key(username)
        format(EMAIL_FETCHED_FOR_PROJECT_CACHE_KEY, project: project.id, username: username)
      end

      def log(message, username: nil)
        Logger.info(
          project_id: project.id,
          class: self.class.name,
          username: username,
          message: message
        )
      end

      def feature_flag_in_lock(lease_key, sleep_sec:, retries:)
        return yield(false) if Feature.disabled?(:github_import_lock_user_finder, project.creator)

        in_lock(lease_key, sleep_sec: sleep_sec, retries: retries) do |retried|
          yield(retried)
        end
      end
    end
  end
end
