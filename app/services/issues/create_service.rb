module Issues
  class CreateService < Issues::BaseService
    def execute
      filter_params
      label_params = params.delete(:label_ids)
      @request = params.delete(:request)
      @api = params.delete(:api)
      @issue = project.issues.new(params)
      @issue.author = params[:author] || current_user

      @issue.spam = spam_service.check(@api)

      if @issue.save
        @issue.update_attributes(label_ids: label_params)
        notification_service.new_issue(@issue, current_user)
        todo_service.new_issue(@issue, current_user)
        event_service.open_issue(@issue, current_user)
        user_agent_detail_service.create
        @issue.create_cross_references!(current_user)
        execute_hooks(@issue, 'open')
      end

      @issue
    end

    private

    def spam_service
      SpamService.new(@issue, @request)
    end

    def user_agent_detail_service
      UserAgentDetailService.new(@issue, @request)
    end
  end
end
