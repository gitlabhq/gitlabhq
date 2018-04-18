module Goldiloader
  module AssociationLoader
    module LimitPreloading
      PreloadingLimitExceeded = Class.new(StandardError)

      private

      def eager_load(models, association_name)
        if Gitlab::Sentry.enabled? && models.count > 100
          Gitlab::Sentry.context

          Raven.capture_exception(PreloadingLimitExceeded.new("More than 100 models preloaded for #{models.first.class}.#{association_name}"))
          return
        end

        super
      rescue => e
        Raven.capture_exception(e)
      end
    end

    prepend LimitPreloading
    singleton_class.prepend LimitPreloading
  end
end
