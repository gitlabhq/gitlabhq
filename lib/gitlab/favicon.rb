module Gitlab
  class Favicon
    class << self
      def main
        return appearance_favicon.favicon_main.url if appearance_favicon.exists?

        image_name =
          if Gitlab::Utils.to_boolean(ENV['CANARY'])
            'favicon-yellow.png'
          elsif Rails.env.development?
            'favicon-green.png'
          else
            'favicon.png'
          end

        ActionController::Base.helpers.image_path(image_name)
      end

      def status_overlay(status_name)
        path = File.join(
          'ci_favicons',
          "#{status_name}.png"
        )

        ActionController::Base.helpers.image_path(path)
      end

      def available_status_names
        @available_status_names ||= begin
          Dir.glob(Rails.root.join('app', 'assets', 'images', 'ci_favicons', '*.png'))
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
    end
  end
end
