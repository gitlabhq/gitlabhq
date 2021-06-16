# frozen_string_literal: true

require 'spec_helper'
require 'shellwords'

RSpec.describe 'bin/sidekiq-cluster' do
  using RSpec::Parameterized::TableSyntax

  context 'when selecting some queues and excluding others' do
    where(:args, :included, :excluded) do
      %w[--negate cronjob] | '-qdefault,1' | '-qcronjob,1'
      %w[--queue-selector resource_boundary=cpu] | '-qupdate_merge_requests,1' | '-qdefault,1'
    end

    with_them do
      it 'runs successfully', :aggregate_failures do
        cmd = %w[bin/sidekiq-cluster --dryrun] + args

        output, status = Gitlab::Popen.popen(cmd, Rails.root.to_s)

        expect(status).to be(0)
        expect(output).to include('bundle exec sidekiq')
        expect(Shellwords.split(output)).to include(included)
        expect(Shellwords.split(output)).not_to include(excluded)
      end
    end
  end

  context 'when selecting all queues' do
    [
      %w[*],
      %w[--queue-selector *]
    ].each do |args|
      it "runs successfully with `#{args}`", :aggregate_failures do
        cmd = %w[bin/sidekiq-cluster --dryrun] + args

        output, status = Gitlab::Popen.popen(cmd, Rails.root.to_s)

        expect(status).to be(0)
        expect(output).to include('bundle exec sidekiq')
        expect(Shellwords.split(output)).to include('-qdefault,1')
        expect(Shellwords.split(output)).to include('-qcronjob:ci_archive_traces_cron,1')
      end
    end
  end
end
