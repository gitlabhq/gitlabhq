module RspecFlaky
  # This is a wrapper class for RSpec::Core::Example
  class Example
    delegate :status, :exception, to: :execution_result

    def initialize(rspec_example)
      @rspec_example = rspec_example.try(:example) || rspec_example
    end

    def uid
      @uid ||= Digest::MD5.hexdigest("#{description}-#{file}")
    end

    def example_id
      rspec_example.id
    end

    def file
      metadata[:file_path]
    end

    def line
      metadata[:line_number]
    end

    def description
      metadata[:full_description]
    end

    def attempts
      rspec_example.try(:attempts) || 1
    end

    private

    attr_reader :rspec_example

    def metadata
      rspec_example.metadata
    end

    def execution_result
      rspec_example.execution_result
    end
  end
end
