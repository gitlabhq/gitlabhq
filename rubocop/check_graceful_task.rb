# frozen_string_literal: true

require_relative 'formatter/graceful_formatter'
require_relative '../lib/gitlab/popen'

module RuboCop
  class CheckGracefulTask
    def initialize(output)
      @output = output
    end

    def run(args)
      options = %w[
        --parallel
        --format RuboCop::Formatter::GracefulFormatter
      ]

      # Convert from Rake::TaskArguments into an Array to make `any?` work as expected.
      cop_names = args.to_a

      if cop_names.any?
        list = cop_names.sort.join(',')
        options.concat ['--only', list]
      end

      puts <<~MSG
        Running RuboCop in graceful mode:
          rubocop #{options.join(' ')}

        This might take a while...
      MSG

      status_orig = RuboCop::CLI.new.run(options)
      status = RuboCop::Formatter::GracefulFormatter.adjusted_exit_status(status_orig)

      # We had to adjust the status which means we have silenced offenses. Notify Slack!
      notify_slack unless status_orig == status

      status
    end

    private

    def env_values(*keys)
      env = ENV.slice(*keys)

      missing_keys = keys - env.keys

      if missing_keys.any?
        puts "Missing ENV keys: #{missing_keys.join(', ')}"
        return
      end

      env.values
    end

    def notify_slack
      job_name, job_url, _ = env_values('CI_JOB_NAME', 'CI_JOB_URL', 'CI_SLACK_WEBHOOK_URL')

      unless job_name
        puts 'Skipping Slack notification.'
        return
      end

      channel = 'f_rubocop'
      message = format(
        ':warning: `%{job_name}` passed :green: but contained <%{job_url}|silenced offenses>. ' \
        'See <%{docs_link}|docs>.',
        docs_link: 'https://docs.gitlab.com/ee/development/rubocop_development_guide.html#silenced-offenses',
        job_name: job_name,
        job_url: job_url)

      emoji = 'rubocop'
      user_name = 'GitLab Bot'

      puts "Notifying Slack ##{channel}."

      _output, result = Gitlab::Popen.popen(['scripts/slack', channel, message, emoji, user_name])
      puts "Failed to notify Slack channel ##{channel}." if result.nonzero?
    end

    def puts(...)
      @output.puts(...)
    end
  end
end
