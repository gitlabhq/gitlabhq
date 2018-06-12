module Pseudonymizer
  class Options
    attr_reader :config
    attr_reader :start_at

    def initialize(config: {})
      @config = config
      @start_at = Time.now.utc
    end

    def output_dir
      File.join(Dir.tmpdir, 'gitlab-pseudonymizer', start_at.iso8601)
    end

    def upload_dir
      File.join(start_at.iso8601)
    end
  end
end
