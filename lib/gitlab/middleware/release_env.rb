module Gitlab # rubocop:disable Naming/FileName
  module Middleware
    # Some of middleware would hold env for no good reason even after the
    # request had already been processed, and we could not garbage collect
    # them due to this. Put this middleware as the first middleware so that
    # it would clear the env after the request is done, allowing GC gets a
    # chance to release memory for the last request.
    ReleaseEnv = Struct.new(:app) do
      def call(env)
        app.call(env).tap { env.clear }
      end
    end
  end
end
