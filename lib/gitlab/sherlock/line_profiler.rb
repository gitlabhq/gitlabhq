module Gitlab
  module Sherlock
    class LineProfiler
      # The minimum amount of time that has to be spent in a file for it to be
      # included in a list of samples.
      MINIMUM_DURATION = 10.0

      def profile(&block)
        if RUBY_ENGINE == 'ruby'
          profile_mri(&block)
        else
          raise NotImplementedError,
            'Line profiling is not supported on this platform'
        end
      end

      def profile_mri
        retval  = nil
        samples = lineprof(/^#{Rails.root.to_s}/) { retval = yield }

        file_samples = aggregate_rblineprof(samples)

        [retval, file_samples]
      end

      # Returns an Array of file samples based on the output of rblineprof.
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

          samples << FileSample.
            new(file, line_samples, total_duration, total_events)
        end

        samples
      end

      def microsec_to_millisec(microsec)
        microsec / 1000.0
      end
    end
  end
end
