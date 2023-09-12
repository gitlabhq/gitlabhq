# frozen_string_literal: true

require 'httparty'

HTTParty::Response.class_eval do
  # Original method: https://github.com/jnunemaker/httparty/blob/v0.20.0/lib/httparty/response.rb#L83-L86
  # Related issue: https://github.com/jnunemaker/httparty/issues/568
  #
  # We need to override this method because `Concurrent::Promise` calls `nil?` on the response when
  # calling the `value` method. And the `value` calls `nil?`.
  # https://github.com/ruby-concurrency/concurrent-ruby/blob/v1.2.2/lib/concurrent-ruby/concurrent/concern/dereferenceable.rb#L64
  def nil?
    response.nil? || response.body.blank?
  end
end
