require 'opentracing'

module Gitlab
  module Tracing
    module Redis

      def self.instrument_client
        ::Redis::Client.class_exec do
          prepend RedisTracingInstrumented
        end
      end

      private

      module RedisTracingInstrumented
        def call(*args, &block)
          span = OpenTracing.start_span("redis.call",
            tags: {
              'component':     'redis',
              'span.kind':     'client',
              'db.host':       self.host,
              'db.port':       self.port,
              'redis.db':      self.db,
              'redis.command': quantize_redis_arguments(*args)
            })

          begin
            super(*args, &block)
          rescue => exception
            span.set_tag('error', true)
            span.log_kv(
              'event':        'error',
              'error.kind':   exception.class.to_s,
              'error.object': exception,
              'message':      exception.message,
              'stack':        exception.backtrace.join("\n")
            )
            raise exception
          ensure
            span.finish
          end
        end

        # Turns an array of redis arguments into a trace-worthy string
        def quantize_redis_arguments(args)
          args.inject("") do |memo, arg|
            str = ""
            begin
              str = arg.to_s.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
            rescue
              # Don't stumble on encoding errors while generating tracing
              str = "?"
            end

            str = str.slice(0, 19) + "…" if str.length > 20

            memo = memo == "" ? str : memo + " " + str
            if memo.length > 120
              memo = memo.slice(0, 119) + "…"
              # No need to iterate over the rest of the arguments
              break memo
            end

            memo
          end
        end
      end
    end
  end
end

