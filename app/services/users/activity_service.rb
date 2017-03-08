module Users
  class ActivityService
    def initialize(author, activity)
      @author = author.respond_to?(:user) ? author.user : author
      @activity = activity
    end

    def execute
      return unless @author && @author.is_a?(User)

      record_activity
    end

    private

    def record_activity
      @author.record_activity unless Gitlab::Geo.secondary?

      Rails.logger.debug("Recorded activity: #{@activity} for User ID: #{@author.id} (username: #{@author.username}")
    end
  end
end
