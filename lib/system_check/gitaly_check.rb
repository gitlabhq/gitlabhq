# frozen_string_literal: true

module SystemCheck
  class GitalyCheck < BaseCheck
    set_name 'Gitaly:'

    def multi_check
      Gitlab::HealthChecks::GitalyCheck.readiness.each do |result|
        $stdout.print "#{result.labels[:shard]} ... "

        if result.success
          $stdout.puts 'OK'.color(:green)
        else
          $stdout.puts "FAIL: #{result.message}".color(:red)
        end
      end
    end
  end
end
