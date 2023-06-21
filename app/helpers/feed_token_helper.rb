# frozen_string_literal: true

module FeedTokenHelper
  def generate_feed_token(type)
    feed_token = current_user&.feed_token
    return unless feed_token

    final_path = "#{current_request.path}.#{type}"
    digest = OpenSSL::HMAC.hexdigest("SHA256", feed_token, final_path)
    "#{User::FEED_TOKEN_PREFIX}#{digest}-#{current_user.id}"
  end
end
