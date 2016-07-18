module Issues
  class SpamCheckService < BaseService
    include Gitlab::AkismetHelper

    def spam_detected?
      text = [params[:title], params[:description]].reject(&:blank?).join("\n")
      request = params[:request]

      if request
        if check_for_spam?(project) && is_spam?(request.env, current_user, text)
          attrs = {
            user_id: current_user.id,
            project_id: project.id,
            title: params[:title],
            description: params[:description]
          }
          create_spam_log(project, current_user, attrs, request.env, api: false)
          return true
        end
      end

      false
    end
  end
end
