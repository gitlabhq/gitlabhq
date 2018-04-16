module EE
  # BroadcastMessage EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `BroadcastMessage` model
  module BroadcastMessage
    extend ActiveSupport::Concern

    module ClassMethods
      extend ::Gitlab::Utils::Override

      override :cache_expires_in
      def cache_expires_in
        if ::Gitlab::Geo.secondary?
          30.seconds
        else
          super
        end
      end
    end
  end
end
