module Gitlab
  module SidekiqVersioning
    module JobRetry
      def global(job, queue)
        super do
          begin
            yield
          rescue NameError => e
            if worker_name_error?(e, job['class']) && SidekiqVersioning.requeue_unsupported_job(nil, job, queue)
              raise Sidekiq::JobRetry::Skip
            else
              raise e
            end
          end
        end
      end

      private

      def worker_name_error?(e, class_name)
        name_match = e.message.match(/uninitialized constant ([A-Za-z:]+)/)

        # If we cannot match the name from the message, we fall back to `e.name`.
        # They are identical, except when namespacing comes into play:
        # If we look up `Foo::BarWorker` and `Foo` exists, `e.name` will be `BarWorker`,
        # while the message will contain the full `Foo::BarWorker` we need.
        error_class_name = name_match ? name_match[1] : e.name.to_s

        # If `class_name` is `Foo::BarWorker`, we'll get an `error_class_name`
        # with either `Foo` or `Foo::BarWorker`.
        class_name.start_with?(error_class_name)
      end
    end
  end
end
