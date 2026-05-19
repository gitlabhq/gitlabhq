# frozen_string_literal: true

module SystemCheck
  class GitalyCheck < BaseCheck
    set_name 'Gitaly:'

    def multi_check
      Gitlab::HealthChecks::GitalyCheck.readiness.each do |result|
        print "#{result.labels[:shard]} ... " # rubocop:disable Rails/Output -- system check CLI output

        if result.success
          say Rainbow('OK').green
        else
          say Rainbow("FAIL: #{result.message}").red
        end
      end
    end
  end
end
