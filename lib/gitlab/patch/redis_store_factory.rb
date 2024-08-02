# frozen_string_literal: true

module Gitlab
  module Patch
    module RedisStoreFactory
      def create
        # rubocop:disable Gitlab/ModuleWithInstanceVariables -- patched code references @options in redis-store
        opt = @options
        # rubocop:enable Gitlab/ModuleWithInstanceVariables
        return Gitlab::Redis::ClusterStore.new(opt) if opt[:nodes]

        super
      end
    end

    # Once https://github.com/redis-store/redis-store/pull/373 is merged
    # and released, we can drop RedisStoreFactoryClassMethods.
    if Gem::Version.new(::Redis::Store::VERSION) > Gem::Version.new("1.10.0")
      raise 'This Redis::Store patch could be removed now the version has changed'
    end

    # rubocop:disable Layout/EndAlignment -- This is upstream code
    # rubocop:disable Layout/HashAlignment -- This is upstream code
    # rubocop:disable Style/HashSyntax -- This is upstream code
    # rubocop:disable Layout/IndentationWidth -- This is upstream code
    # rubocop:disable Layout/LineLength -- This is upstream code
    # rubocop:disable Performance/RedundantSplitRegexpArgument -- This is upstream code
    # rubocop:disable Style/IfUnlessModifier -- This is upstream code
    # rubocop:disable Style/RegexpLiteralMixedPreserve -- This is upstream code
    module RedisStoreFactoryClassMethods
      def extract_host_options_from_uri(uri)
        uri = URI.parse(uri)
        if uri.scheme == "unix"
          options = { :path => uri.path }
        else
          _, db, namespace = if uri.path
            uri.path.split(/\//)
          end

          options = {
            :scheme   => uri.scheme,
            :host     => uri.hostname,
            :port     => uri.port || ::Redis::Store::Factory::DEFAULT_PORT,
            :ssl      => uri.scheme == 'rediss'
          }

          options[:db]        = db.to_i   if db
          options[:namespace] = namespace if namespace
        end

        if uri.user && !uri.user.empty?
          options[:username] = uri.user
        end

        options[:password] = CGI.unescape(uri.password.to_s) if uri.password

        if uri.query
          query = Hash[URI.decode_www_form(uri.query)]
          query.each do |(key, value)|
            options[key.to_sym] = value
          end
        end

        options
      end
    end
    # rubocop:enable Layout/EndAlignment
    # rubocop:enable Layout/HashAlignment
    # rubocop:enable Style/HashSyntax
    # rubocop:enable Layout/IndentationWidth
    # rubocop:enable Layout/LineLength
    # rubocop:enable Performance/RedundantSplitRegexpArgument
    # rubocop:enable Style/IfUnlessModifier
    # rubocop:enable Style/RegexpLiteralMixedPreserve
  end
end
