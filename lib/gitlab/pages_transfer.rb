# frozen_string_literal: true

# To make a call happen in a new Sidekiq job, add `.async` before the call. For
# instance:
#
#   PagesTransfer.new.async.move_namespace(...)
#
module Gitlab
  class PagesTransfer < ProjectTransfer
    class Async
      METHODS = %w[move_namespace move_project rename_project rename_namespace].freeze

      METHODS.each do |meth|
        define_method meth do |*args|
          PagesTransferWorker.perform_async(meth, args)
        end
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
