module Gitlab
  class Favicon
    class << self
      def main
        image_name =
          if appearance_favicon.exists?
            appearance_favicon.url
          elsif Gitlab::Utils.to_boolean(ENV['CANARY'])
            'favicon-yellow.png'
          elsif Rails.env.development?
            'favicon-blue.png'
          else
            'favicon.png'
          end

        ActionController::Base.helpers.image_path(image_name, host: host)
      end

      def status_overlay(status_name)
        path = File.join(
          'ci_favicons',
          "#{status_name}.png"
        )

        ActionController::Base.helpers.image_path(path, host: host)
      end

      def available_status_names
        @available_status_names ||= begin
          Dir.glob(Rails.root.join('app', 'assets', 'images', 'ci_favicons', '*.png'))
            .map { |file| File.basename(file, '.png') }
            .sort
        end
      end

      private

      # we only want to create full urls when there's a different asset_host
      # configured.
      def host
        asset_host = ActionController::Base.asset_host
        if asset_host.nil? || asset_host == Gitlab.config.gitlab.base_url
          nil
        else
          Gitlab.config.gitlab.base_url
        end
      end

      def appearance
        RequestStore.store[:appearance] ||= (Appearance.current || Appearance.new)
      end

      def appearance_favicon
        appearance.favicon
      end
    end
  end
end
