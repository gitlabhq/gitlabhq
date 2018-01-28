module Gitlab
  module StorageCheck
    class OptionParser
      def self.parse!(args)
        # Start out with some defaults
        options = Gitlab::StorageCheck::Options.new(nil, nil, 1, false)

        parser = ::OptionParser.new do |opts|
          opts.banner = "Usage: bin/storage_check [options]"

          opts.on('-t=string', '--target string', 'URL or socket to trigger storage check') do |value|
            options.target = value
          end

          opts.on('-T=string', '--token string', 'Health token to use') { |value| options.token = value }

          opts.on('-i=n', '--interval n', ::OptionParser::DecimalInteger, 'Seconds between checks') do |value|
            options.interval = value
          end

          opts.on('-d', '--dryrun', "Output what will be performed, but don't start the process") do |value|
            options.dryrun = value
          end
        end
        parser.parse!(args)

        unless options.target
          raise ::OptionParser::InvalidArgument.new('Provide a URI to provide checks')
        end

        if URI.parse(options.target).scheme.nil?
          raise ::OptionParser::InvalidArgument.new('Add the scheme to the target, `unix://`, `https://` or `http://` are supported')
        end

        options
      end
    end
  end
end
