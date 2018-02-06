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
          flaky_reports: 0)
      else
        super
      end
    end

    def update_flakiness!(last_attempts_count: nil)
      self.first_flaky_at ||= Time.now
      self.last_flaky_at = Time.now
      self.flaky_reports += 1
      self.last_attempts_count = last_attempts_count if last_attempts_count

      if ENV['CI_PROJECT_URL'] && ENV['CI_JOB_ID']
        self.last_flaky_job = "#{ENV['CI_PROJECT_URL']}/-/jobs/#{ENV['CI_JOB_ID']}"
      end
    end

    def to_h
      super.merge(
        first_flaky_at: first_flaky_at,
        last_flaky_at: last_flaky_at,
        last_flaky_job: last_flaky_job)
    end
  end
end
