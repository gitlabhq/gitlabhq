class SpamCheckService
  include Gitlab::AkismetHelper

  attr_accessor :subject, :current_user, :params

  def initialize(subject, user, params = {})
    @subject, @current_user, @params = subject, user, params.dup
  end

  def spam_detected?
    request = params[:request]
    return false unless request || check_for_spam?(subject)

    text = [params[:title], params[:description]].reject(&:blank?).join("\n")

    return false unless is_spam?(request.env, current_user, text)

    attrs = {
      user_id: current_user.id,
      project_id: subject.id,
      title: params[:title],
      description: params[:description]
    }
    create_spam_log(subject, current_user, attrs, request.env, api: false)

    true
  end
end
