# frozen_string_literal: true

module FeedTokenHelper
  def generate_feed_token(type)
    generate_feed_token_with_path(type, current_request.path)
  end

  def generate_feed_token_with_path(type, path)
    feed_token = current_user&.feed_token
    return unless feed_token

    final_path = path
    final_path += ".#{type}" unless path.ends_with?(".#{type}")
    digest = OpenSSL::HMAC.hexdigest("SHA256", feed_token, final_path)
    "#{User::FEED_TOKEN_PREFIX}#{digest}-#{current_user.id}"
  end
end
