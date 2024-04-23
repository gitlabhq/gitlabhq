# frozen_string_literal: true

if Gem::Version.new(Sidekiq::VERSION) != Gem::Version.new('7.1.6')
  raise 'New version of sidekiq detected, please remove or update this patch'
end

module Gitlab
  module Patch
    module SidekiqJobSetter
      # Sidekiq::Job::Setter's .perform_in and .perform_async indirectly calls perform_async
      # so we only need to patch 1 method.
      def perform_async(*args)
        # rubocop:disable Gitlab/ModuleWithInstanceVariables -- @klass is present in the class we are patching
        Gitlab::SidekiqSharding::Router.route(@klass) do
          # rubocop:enable Gitlab/ModuleWithInstanceVariables
          super
        end
      end
    end
  end
end
