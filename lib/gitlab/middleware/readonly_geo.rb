module Gitlab
  module Middleware
    class ReadonlyGeo
      READONLY_METHODS = %w(PATCH PUT DELETE)

      def initialize(app)
        @app = app
      end

      def call(env)
        if READONLY_METHODS.include?(env['REQUEST_METHOD']) && Gitlab::Geo.readonly?
          Rails.logger.debug('Gitlab Geo: preventing possible non readonly operation')

          rflash = rack_flash(env)
          rflash.alert= 'You are using Gitlab Geo'
          env['rack.session']['flash'] = rflash.to_session_value

          #TODO: should redirect to last visited page or root url
        end

        @app.call(env)
      end

      private

      def rack_flash(env)
        ActionDispatch::Flash::FlashHash.from_session_value(env['rack.session'])
      end
    end
  end
end
