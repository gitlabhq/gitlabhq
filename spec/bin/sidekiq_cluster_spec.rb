# frozen_string_literal: true

require 'fast_spec_helper'
require 'shellwords'
require 'rspec-parameterized'

RSpec.describe 'bin/sidekiq-cluster', :uses_fast_spec_helper_but_runs_slow, :fails_if_sidekiq_not_configured, :aggregate_failures do
  using RSpec::Parameterized::TableSyntax

  let(:root) { File.expand_path('../..', __dir__) }

  # This test assumes sidekiq.routing_rules setting in gitlab.yml is empty
  # and the default is `[['*', 'default']]`. Any queue listed in the argument
  # would be replaced by default and mailers queue.
  # If routing rules is configured, the tests below might fail.
  context 'when specifying some queues' do
    where(:args, :included) do
      %w[foo,bar] | %w[-qdefault,1 -qmailers,1]
      %w[*] | %w[-qdefault,1 -qmailers,1]
      %w[* foo,bar] | %w[-qdefault,1 -qmailers,1]
    end

    with_them do
      it 'runs successfully' do
        cmd = %w[bin/sidekiq-cluster --dryrun] + args

        output, status = Gitlab::Popen.popen(cmd, root)

        expect(status).to be(0)
        expect(output).to include('bundle exec sidekiq')
        expect(Shellwords.split(output)).to include(*included)
      end
    end
  end

  context 'when specifying queues in mulitple arguments' do
    it 'runs successfully' do
      cmd = %w[bin/sidekiq-cluster --dryrun * foo,bar]

      output, status = Gitlab::Popen.popen(cmd, root)

      expect(status).to be(0)
      expect(output).to include('bundle exec sidekiq')
      output_array = output.split("\n")
      expect(output_array.length).to eq(2)
      expect(Shellwords.split(output_array.first)).to include(*%w[-qdefault,1 -qmailers,1])
      expect(Shellwords.split(output_array.second)).to include(*%w[-qdefault,1 -qmailers,1])
    end
  end

  context 'when arguments contain newlines' do
    it 'raises an error' do
      [
        ["default\n"],
        ["defaul\nt"]
      ].each do |args|
        cmd = %w[bin/sidekiq-cluster --dryrun] + args

        output, status = Gitlab::Popen.popen(cmd, root)

        expect(status).to be(1)
        expect(output).to include('cannot contain newlines')
      end
    end
  end
end
