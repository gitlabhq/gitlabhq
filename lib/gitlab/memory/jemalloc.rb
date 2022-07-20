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

      FILENAME_PREFIX = 'jemalloc_stats'

      # Return jemalloc stats as a string.
      def stats(format: STATS_DEFAULT_FORMAT)
        verify_format!(format)

        with_malloc_stats_print do |stats_print|
          StringIO.new.tap { |io| write_stats(stats_print, io, STATS_FORMATS[format]) }.string
        end
      end

      # Write jemalloc stats to the given directory
      # @param [String] path Directory path the dump will be put into
      # @param [String] format `json` or `txt`
      # @param [String] filename_label Optional custom string that will be injected into the file name, e.g. `worker_0`
      # @return [void]
      def dump_stats(path:, format: STATS_DEFAULT_FORMAT, filename_label: nil)
        verify_format!(format)

        with_malloc_stats_print do |stats_print|
          format_settings = STATS_FORMATS[format]
          File.open(File.join(path, file_name(format_settings[:extension], filename_label)), 'wb') do |io|
            write_stats(stats_print, io, format_settings)
          end
        end
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

      def file_name(extension, filename_label)
        [FILENAME_PREFIX, $$, filename_label, Time.current.to_i, extension].reject(&:blank?).join('.')
      end
    end
  end
end
