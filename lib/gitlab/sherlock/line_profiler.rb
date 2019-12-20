# frozen_string_literal: true

module Gitlab
  module Sherlock
    # Class for profiling code on a per line basis.
    #
    # The LineProfiler class can be used to profile code on per line basis
    # without littering your code with Ruby implementation specific profiling
    # methods.
    #
    # This profiler only includes samples taking longer than a given threshold
    # and those that occur in the actual application (e.g. files from Gems are
    # ignored).
    class LineProfiler
      # The minimum amount of time that has to be spent in a file for it to be
      # included in a list of samples.
      MINIMUM_DURATION = 10.0

      # Profiles the given block.
      #
      # Example:
      #
      #     profiler = LineProfiler.new
      #
      #     retval, samples = profiler.profile do
      #       "cats are amazing"
      #     end
      #
      #     retval  # => "cats are amazing"
      #     samples # => [#<Gitlab::Sherlock::FileSample ...>, ...]
      #
      # Returns an Array containing the block's return value and an Array of
      # FileSample objects.
      def profile(&block)
        if mri?
          profile_mri(&block)
        else
          raise NotImplementedError,
            'Line profiling is not supported on this platform'
        end
      end

      # Profiles the given block using rblineprof (MRI only).
      def profile_mri
        require 'rblineprof'

        retval  = nil
        samples = lineprof(/^#{Rails.root}/) { retval = yield }

        file_samples = aggregate_rblineprof(samples)

        [retval, file_samples]
      end

      # Returns an Array of file samples based on the output of rblineprof.
      #
      # lineprof_stats - A Hash containing rblineprof statistics on a per file
      #                  basis.
      #
      # Returns an Array of FileSample objects.
      def aggregate_rblineprof(lineprof_stats)
        samples = []

        lineprof_stats.each do |(file, stats)|
          source_lines = File.read(file).each_line.to_a
          line_samples = []

          total_duration = microsec_to_millisec(stats[0][0])
          total_events   = stats[0][2]

          next if total_duration <= MINIMUM_DURATION

          stats[1..-1].each_with_index do |data, index|
            next unless source_lines[index]

            duration = microsec_to_millisec(data[0])
            events   = data[2]

            line_samples << LineSample.new(duration, events)
          end

          samples << FileSample
            .new(file, line_samples, total_duration, total_events)
        end

        samples
      end

      private

      def microsec_to_millisec(microsec)
        microsec / 1000.0
      end

      def mri?
        RUBY_ENGINE == 'ruby'
      end
    end
  end
end
