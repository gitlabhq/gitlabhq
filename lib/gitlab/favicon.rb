module Gitlab
  class Favicon
    class << self
      def default
        return custom_favicon_url(appearance_favicon.default.url) if appearance_favicon.exists?
        return 'favicon-yellow.ico' if Gitlab::Utils.to_boolean(ENV['CANARY'])
        return 'favicon-blue.ico' if Rails.env.development?

        'favicon.ico'
      end

      def status(status_name)
        if appearance_favicon.exists?
          custom_favicon_url(appearance_favicon.public_send("status_#{status_name}").url) # rubocop:disable GitlabSecurity/PublicSend
        else
          dir = 'ci_favicons'
          dir = File.join(dir, 'dev') if Rails.env.development?
          dir = File.join(dir, 'canary') if Gitlab::Utils.to_boolean(ENV['CANARY'])

          File.join(dir, "favicon_status_#{status_name}.ico")
        end
      end

      private

      def appearance
        Appearance.current || Appearance.new
      end

      def appearance_favicon
        appearance.favicon
      end

      # Without the '?' at the end of the favicon url the custom favicon (i.e.
      # the favicons that are served through `UploadController`) are not shown
      # in the browser.
      def custom_favicon_url(url)
        "#{url}?"
      end
    end
  end
end
