# frozen_string_literal: true

module Gitlab
  class Favicon
    class << self
      def main
        image_name =
          if appearance.favicon.exists?
            appearance.favicon_path
          elsif Gitlab.canary?
            'favicon-yellow.png'
          elsif Rails.env.development?
            development_favicon
          else
            'favicon.png'
          end

        ActionController::Base.helpers.image_path(image_name, host: host)
      end

      def development_favicon
        # This is a separate method so that EE can return a different favicon
        # for development environments.
        'favicon-blue.png'
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
        Gitlab::SafeRequestStore[:appearance] ||= (Appearance.current || Appearance.new)
      end
    end
  end
end

Gitlab::Favicon.prepend_mod_with('Gitlab::Favicon')
