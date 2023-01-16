# frozen_string_literal: true

return unless Rails.env.test?

module RspecProfilingExt
  module Collectors
    class CSVWithTimestamps < ::RspecProfiling::Collectors::CSV
      TIMESTAMP_FIELDS = %w(created_at updated_at).freeze
      METADATA_FIELDS = %w(feature_category).freeze
      HEADERS = (::RspecProfiling::Collectors::CSV::HEADERS + TIMESTAMP_FIELDS + METADATA_FIELDS).freeze

      def insert(attributes)
        output << HEADERS.map do |field|
          if TIMESTAMP_FIELDS.include?(field)
            Time.now
          else
            attributes.fetch(field.to_sym)
          end
        end
      end

      private

      def output
        @output ||= ::CSV.open(path, "w").tap { |csv| csv << HEADERS }
      end
    end
  end

  module Git
    def branch
      if ENV['CI_COMMIT_REF_NAME']
        "#{defined?(Gitlab::License) ? 'ee' : 'ce'}:#{ENV['CI_COMMIT_REF_NAME']}"
      else
        super&.chomp
      end
    end

    def sha
      super&.chomp
    end
  end

  module Example
    def feature_category
      metadata[:feature_category]
    end
  end

  module Run
    def example_finished(*args)
      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      collector.insert({
        branch: vcs.branch,
                         commit_hash: vcs.sha,
                         date: vcs.time,
                         file: @current_example.file,
                         line_number: @current_example.line_number,
                         description: @current_example.description,
                         status: @current_example.status,
                         exception: @current_example.exception,
                         time: @current_example.time,
                         query_count: @current_example.query_count,
                         query_time: @current_example.query_time,
                         request_count: @current_example.request_count,
                         request_time: @current_example.request_time,
                         feature_category: @current_example.feature_category
      })
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    rescue StandardError => err
      return if @already_logged_example_finished_error # rubocop:disable Gitlab/ModuleWithInstanceVariables

      warn "rspec_profiling couldn't collect an example: #{err}. Further warnings suppressed."
      @already_logged_example_finished_error = true # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    alias_method :example_passed, :example_finished
    alias_method :example_failed, :example_finished
  end
end

RspecProfiling.configure do |config|
  if ENV.key?('CI') || ENV.key?('RSPEC_PROFILING')
    RspecProfiling::VCS::Git.prepend(RspecProfilingExt::Git)
    RspecProfiling::Run.prepend(RspecProfilingExt::Run)
    RspecProfiling::Example.prepend(RspecProfilingExt::Example)
    config.collector = RspecProfilingExt::Collectors::CSVWithTimestamps
    config.csv_path = -> do
      prefix = "#{ENV['CI_JOB_NAME']}-".gsub(%r{[ /]}, '-') if ENV['CI_JOB_NAME']
      "#{ENV['RSPEC_PROFILING_FOLDER_PATH']}/#{prefix}#{Time.now.to_i}-#{SecureRandom.hex(8)}-rspec-data.csv"
    end
  end
end
