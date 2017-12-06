module Gitlab
  class Favicon
    class << self
      def main
        return custom_favicon_url(appearance_favicon.favicon_main.url) if appearance_favicon.exists?
        return 'favicon-yellow.ico' if Gitlab::Utils.to_boolean(ENV['CANARY'])
        return 'favicon-green.ico' if Rails.env.development?

        'favicon.ico'
      end

      def status_overlay(status_name)
        path = File.join(
          'ci_favicons',
          'overlays',
          "#{status_name}.png"
        )

        ActionController::Base.helpers.image_path(path)
      end

      def available_status_overlays
        available_status_names.map do |status_name|
          status_overlay(status_name)
        end
      end

      def available_status_names
        @available_status_names ||= begin
          Dir.glob(Rails.root.join('app', 'assets', 'images', 'ci_favicons', 'overlays', "*.png"))
            .map { |file| File.basename(file, '.png') }
            .sort
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
