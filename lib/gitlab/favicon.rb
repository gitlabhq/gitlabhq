module Gitlab
  class Favicon
    class << self
      def default
        return appearance_favicon.default.url if appearance_favicon
        return 'favicon-yellow.ico' if Gitlab::Utils.to_boolean(ENV['CANARY'])
        return 'favicon-green.ico' if Rails.env.development?

        'favicon.ico'
      end

      private

      def appearance
        @appearance ||= Appearance.current
      end

      def appearance_favicon
        appearance&.favicon
      end
    end
  end
end
