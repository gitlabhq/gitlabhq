# frozen_string_literal: true

module SystemCheck
  class GitalyCheck < BaseCheck
    set_name 'Gitaly:'

    def multi_check
      Gitlab::HealthChecks::GitalyCheck.readiness.each do |result|
        $stdout.print "#{result.labels[:shard]} ... "

        if result.success
          $stdout.puts Rainbow('OK').green
        else
          $stdout.puts Rainbow("FAIL: #{result.message}").red
        end
      end
    end
  end
end
