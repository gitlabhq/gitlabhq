module Geo
  class BaseNotify
    def notify(notify_url, content)
      response = Gitlab::HTTP.post(notify_url,
                                   timeout: Gitlab.config.gitlab.webhook_timeout,
                                   body: content,
                                   allow_local_requests: true,
                                   headers: {
                                     'Content-Type' => 'application/json',
                                     'PRIVATE-TOKEN' => private_token
                                   })

      [(response.code >= 200 && response.code < 300), ActionView::Base.full_sanitizer.sanitize(response.to_s)]
    rescue Gitlab::HTTP::Error, Errno::ECONNREFUSED => e
      [false, ActionView::Base.full_sanitizer.sanitize(e.message)]
    end

    private

    def private_token
      # TODO: should we ask admin user to be defined as part of configuration?
      @private_token ||= User.find_by(admin: true).authentication_token
    end
  end
end
