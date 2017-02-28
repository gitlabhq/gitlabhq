module Groups
  class BaseService < ::BaseService
    attr_accessor :group, :current_user, :params

    def initialize(group, user, params = {})
      @group, @current_user, @params = group, user, params.dup
    end

    private

    def create_chat_team?
      @chat_team == true && Gitlab.config.mattermost.enabled
    end
  end
end
