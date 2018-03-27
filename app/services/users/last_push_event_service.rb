module Users
  # Service class for caching and retrieving the last push event of a user.
  class LastPushEventService
    EXPIRATION = 2.hours

    def initialize(user)
      @user = user
    end

    # Caches the given push event for the current user in the Rails cache.
    #
    # event - An instance of PushEvent to cache.
    def cache_last_push_event(event)
      keys = [
        project_cache_key(event.project),
        user_cache_key
      ]

      if forked_from = event.project.forked_from_project
        keys << project_cache_key(forked_from)
      end

      keys.each { |key| set_key(key, event.id) }
    end

    # Returns the last PushEvent for the current user.
    #
    # This method will return nil if no event was found.
    def last_event_for_user
      find_cached_event(user_cache_key)
    end

    # Returns the last PushEvent for the current user and the given project.
    #
    # project - An instance of Project for which to retrieve the PushEvent.
    #
    # This method will return nil if no event was found.
    def last_event_for_project(project)
      find_cached_event(project_cache_key(project))
    end

    def find_cached_event(cache_key)
      event_id = get_key(cache_key)

      return unless event_id

      unless (event = find_event_in_database(event_id))
        # We don't want to keep querying the same data over and over when a
        # merge request has been created, thus we remove the key if no event
        # (meaning an MR was created) is returned.
        Rails.cache.delete(cache_key)
      end

      event
    end

    private

    def find_event_in_database(id)
      PushEvent
        .without_existing_merge_requests
        .find_by(id: id)
    end

    def user_cache_key
      "last-push-event/#{@user.id}"
    end

    def project_cache_key(project)
      "last-push-event/#{@user.id}/#{project.id}"
    end

    def get_key(key)
      Rails.cache.read(key, raw: true)
    end

    def set_key(key, value)
      # We're using raw values here since this takes up less space and we don't
      # store complex objects.
      Rails.cache.write(key, value, raw: true, expires_in: EXPIRATION)
    end
  end
end
