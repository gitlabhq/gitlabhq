module Pseudonymizer
  class Options
    attr_reader :config
    attr_reader :start_at

    def initialize(config: {}, start_at: Time.now.utc)
      @config = config
      @start_at = start_at
    end

    def output_dir
      File.join('/tmp', 'gitlab-pseudonymizer', start_at.iso8601)
    end

    def upload_dir
      File.join(start_at.iso8601)
    end
  end
end
