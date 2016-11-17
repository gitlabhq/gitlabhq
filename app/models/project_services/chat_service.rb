# Base class for Chat services
# This class is not meant to be used directly, but only to inherrit from.
class ChatService < Service
  default_value_for :category, 'chat'

  has_many :chat_names, foreign_key: :service_id

  def valid_token?(token)
    self.respond_to?(:token) &&
      self.token.present? &&
      ActiveSupport::SecurityUtils.variable_size_secure_compare(token, self.token)
  end

  def supported_events
    []
  end

  def trigger(params)
    raise NotImplementedError
  end
end
