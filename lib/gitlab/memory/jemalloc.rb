# frozen_string_literal: true

require 'fiddle'

module Gitlab
  module Memory
    module Jemalloc
      extend self

      STATS_FORMATS = {
        json: { options: 'J', extension: 'json' },
        text: { options: '', extension: 'txt' }
      }.freeze

      STATS_DEFAULT_FORMAT = :json

      # Return jemalloc stats as a string.
      def stats(format: STATS_DEFAULT_FORMAT)
        dump_stats(StringIO.new, format: format).string
      end

      # Streams jemalloc stats to the given IO object.
      def dump_stats(io, format: STATS_DEFAULT_FORMAT)
        verify_format!(format)

        format_settings = STATS_FORMATS[format]

        with_malloc_stats_print do |stats_print|
          write_stats(stats_print, io, format_settings)
        end

        io
      end

      private

      def verify_format!(format)
        raise "format must be one of #{STATS_FORMATS.keys}" unless STATS_FORMATS.key?(format)
      end

      def with_malloc_stats_print
        fiddle_func = malloc_stats_print
        return unless fiddle_func

        yield fiddle_func
      end

      def malloc_stats_print
        method = Fiddle::Handle.sym("malloc_stats_print")

        Fiddle::Function.new(
          method,
          # C signature:
          # void (write_cb_t *write_cb, void *cbopaque, const char *opts)
          #   arg1: callback function pointer (see below)
          #   arg2: pointer to cbopaque holding additional callback data; always NULL here
          #   arg3: options string, affects output format (text or JSON)
          #
          # Callback signature (write_cb_t):
          # void (void *, const char *)
          #   arg1: pointer to cbopaque data (see above; unused)
          #   arg2: pointer to string buffer holding textual output
          [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
          Fiddle::TYPE_VOID
        )
      rescue Fiddle::DLError
        # This means the Fiddle::Handle to jemalloc was not open (jemalloc wasn't loaded)
        # or already closed. Eiher way, return nil.
      end

      def write_stats(stats_print, io, format)
        callback = Fiddle::Closure::BlockCaller.new(
          Fiddle::TYPE_VOID, [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP]) do |_, fragment|
          io << fragment
        end

        stats_print.call(callback, nil, format[:options])
      end
    end
  end
end
