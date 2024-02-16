# frozen_string_literal: true

require 'fast_spec_helper'
require 'shellwords'
require 'rspec-parameterized'

RSpec.describe 'bin/sidekiq-cluster', :aggregate_failures do
  using RSpec::Parameterized::TableSyntax

  let(:root) { File.expand_path('../..', __dir__) }

  context 'when selecting some queues and excluding others' do
    where(:args, :included, :excluded) do
      %w[--negate cronjob] | '-qdefault,1' | '-qcronjob,1'
      %w[--queue-selector resource_boundary=cpu] | %w[-qdefault,1 -qmailers,1] |
        '-qauthorized_keys_worker,1'
    end

    with_them do
      it 'runs successfully' do
        cmd = %w[bin/sidekiq-cluster --dryrun] + args

        output, status = Gitlab::Popen.popen(cmd, root)

        expect(status).to be(0)
        expect(output).to include('bundle exec sidekiq')
        expect(Shellwords.split(output)).to include(*included)
        expect(Shellwords.split(output)).not_to include(*excluded)
      end
    end
  end

  context 'when selecting all queues' do
    [
      %w[*],
      %w[--queue-selector *]
    ].each do |args|
      it "runs successfully with `#{args}`" do
        cmd = %w[bin/sidekiq-cluster --dryrun] + args

        output, status = Gitlab::Popen.popen(cmd, root)

        expect(status).to be(0)
        expect(output).to include('bundle exec sidekiq')
        expect(Shellwords.split(output)).to include('-qdefault,1')
        expect(Shellwords.split(output)).to include('-qmailers,1')
      end
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
