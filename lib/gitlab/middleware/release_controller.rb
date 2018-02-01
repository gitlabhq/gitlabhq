module Gitlab
  module Middleware
    ReleaseController = Struct.new(:app) do
      def call(env)
        app.call(env).tap { env.delete('action_controller.instance') }
      end
    end
  end
end
