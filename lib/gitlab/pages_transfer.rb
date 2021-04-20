# frozen_string_literal: true

# To make a call happen in a new Sidekiq job, add `.async` before the call. For
# instance:
#
#   PagesTransfer.new.async.move_namespace(...)
#
module Gitlab
  class PagesTransfer < ProjectTransfer
    METHODS = %w[move_namespace move_project rename_project rename_namespace].freeze

    class Async
      METHODS.each do |meth|
        define_method meth do |*args|
          next unless Settings.pages.local_store.enabled

          PagesTransferWorker.perform_async(meth, args)
        end
      end
    end

    METHODS.each do |meth|
      define_method meth do |*args|
        next unless Settings.pages.local_store.enabled

        super(*args)
      end
    end

    def async
      @async ||= Async.new
    end

    def root_dir
      Gitlab.config.pages.path
    end
  end
end
