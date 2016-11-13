# Base class for Chat services
class ChatService < Service
  default_value_for :category, 'chat'

  has_many :chat_users

  def valid_token?(token)
    self.respond_to?(:token) && self.token.present? && ActiveSupport::SecurityUtils.variable_size_secure_compare(token, self.token)
  end

  def supported_events
  end

  def trigger(params)
    # implement inside child
  end

  def chat_user_params(params)
    params.permit()
  end
end
