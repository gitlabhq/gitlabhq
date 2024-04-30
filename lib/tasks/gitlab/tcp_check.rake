# frozen_string_literal: true

namespace :gitlab do
  desc "GitLab | Check TCP connectivity to a specific host and port"
  task :tcp_check, [:host, :port] => :environment do |_t, args|
    unless args.host && args.port
      puts Rainbow("Please specify a host and port: `rake gitlab:tcp_check[example.com,80]`").red
      exit 1
    end

    checker = Gitlab::TcpChecker.new(args.host, args.port)

    if checker.check
      puts Rainbow("TCP connection from #{checker.local} to #{checker.remote} succeeded").green
    else
      puts Rainbow("TCP connection to #{checker.remote} failed: #{checker.error}").red
      puts
      puts 'Check that host and port are correct, and that the traffic is permitted through any firewalls.'
      exit 1
    end
  end
end
