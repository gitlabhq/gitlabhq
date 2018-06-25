module Pseudonymizer
  class Options
    attr_reader :config
    attr_reader :start_at
    attr_reader :output_dir

    def initialize(config: {}, output_dir: nil)
      @config = config
      @start_at = Time.now.utc

      base_dir = output_dir || File.join(Dir.tmpdir, 'gitlab-pseudonymizer')
      @output_dir = File.join(base_dir, batch_dir)
    end

    def upload_dir
      batch_dir
    end

    private

    def batch_dir
      start_at.iso8601
    end
  end
end
