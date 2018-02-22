namespace :gitlab do
  desc "GitLab | Check SSL connectivity and verify certificates for a specific host and port"
  task :ssl_check => :environment do
    unless ENV['HOST']
      puts "Please specify a host and/or port: `rake gitlab:ssl_check HOST=example.com`".color(:red)
      exit 1
    end

    checker = Gitlab::SslChecker.new(ENV['HOST'], (ENV['PORT'] || 443))

    if checker.check
      puts checker.output
      puts
      puts "SSL connection to #{checker.remote} succeeded".color(:green)
    else
      puts "SSL connection to #{checker.remote} failed: #{checker.error}".color(:red)
      exit 1
    end
  end
end