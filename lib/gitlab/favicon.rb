module Gitlab
  class Favicon
    class << self
      def main
        return custom_favicon_url(appearance_favicon.favicon_main.url) if appearance_favicon.exists?
        return 'favicon-yellow.ico' if Gitlab::Utils.to_boolean(ENV['CANARY'])
        return 'favicon-green.ico' if Rails.env.development?

        'favicon.ico'
      end

      def status(status_name)
        if appearance_favicon.exists?
          custom_favicon_url(appearance_favicon.public_send("#{status_name}").url) # rubocop:disable GitlabSecurity/PublicSend
        else
          path = File.join(
            'ci_favicons',
            Rails.env.development? ? 'dev' : '',
            Gitlab::Utils.to_boolean(ENV['CANARY']) ? 'canary' : '',
            "#{status_name}.ico"
          )

          ActionController::Base.helpers.image_path(path)
        end
      end

      private

      def appearance
        RequestStore.store[:appearance] ||= (Appearance.current || Appearance.new)
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
