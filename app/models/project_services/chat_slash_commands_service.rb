# Base class for Chat services
# This class is not meant to be used directly, but only to inherrit from.
class ChatSlashCommandsService < Service
  default_value_for :category, 'chat'

  prop_accessor :token

  has_many :chat_names, foreign_key: :service_id, dependent: :destroy

  def valid_token?(token)
    self.respond_to?(:token) &&
      self.token.present? &&
      ActiveSupport::SecurityUtils.variable_size_secure_compare(token, self.token)
  end

  def self.supported_events
    %w()
  end

  def can_test?
    false
  end

  def fields
    [
      { type: 'text', name: 'token', placeholder: '' }
    ]
  end

  def trigger(params)
    return unless valid_token?(params[:token])

    user = find_chat_user(params)
    unless user
      url = authorize_chat_name_url(params)
      return presenter.authorize_chat_name(url)
    end

    Gitlab::ChatCommands::Command.new(project, user,
      params).execute
  end

  private

  def find_chat_user(params)
    ChatNames::FindUserService.new(self, params).execute
  end

  def authorize_chat_name_url(params)
    ChatNames::AuthorizeUserService.new(self, params).execute
  end

  def presenter
    Gitlab::ChatCommands::Presenter.new
  end
end
