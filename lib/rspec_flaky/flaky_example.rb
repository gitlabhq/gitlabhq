module RspecFlaky
  # This represents a flaky RSpec example and is mainly meant to be saved in a JSON file
  class FlakyExample < OpenStruct
    def initialize(example)
      if example.respond_to?(:example_id)
        super(
          example_id: example.example_id,
          file: example.file,
          line: example.line,
          description: example.description,
          last_attempts_count: example.attempts,
          flaky_reports: 1)
      else
        super
      end
    end

    def first_flaky_at
      self[:first_flaky_at] || Time.now
    end

    def last_flaky_at
      Time.now
    end

    def last_flaky_job
      return unless ENV['CI_PROJECT_URL'] && ENV['CI_JOB_ID']

      "#{ENV['CI_PROJECT_URL']}/-/jobs/#{ENV['CI_JOB_ID']}"
    end

    def to_h
      super.merge(
        first_flaky_at: first_flaky_at,
        last_flaky_at: last_flaky_at,
        last_flaky_job: last_flaky_job)
    end
  end
end
