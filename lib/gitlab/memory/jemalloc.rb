# frozen_string_literal: true

require 'ffi'

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
        stats_print = malloc_stats_print
        return unless stats_print

        yield stats_print
      end

      def malloc_stats_print
        # Look up malloc_stats_print in the current process. When jemalloc is not
        # loaded the symbol is absent and find_function returns nil, in which case
        # we return nil too.
        symbol = current_process.find_function('malloc_stats_print')
        return unless symbol

        FFI::Function.new(
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
          :void,
          [:pointer, :pointer, :string],
          symbol
        )
      end

      def write_stats(stats_print, io, format)
        callback = FFI::Function.new(:void, [:pointer, :string]) do |_cbopaque, fragment|
          io << fragment
        end

        stats_print.call(callback, nil, format[:options])
      end

      # Handle to the current process, used to resolve symbols loaded into it
      # (e.g. jemalloc when injected via LD_PRELOAD).
      def current_process
        FFI::DynamicLibrary.open(
          nil, FFI::DynamicLibrary::RTLD_LAZY | FFI::DynamicLibrary::RTLD_GLOBAL
        )
      end
    end
  end
end
