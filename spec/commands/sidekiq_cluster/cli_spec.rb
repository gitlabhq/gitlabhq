# frozen_string_literal: true

require 'spec_helper'
require 'gitlab/rspec/next_instance_of'

require_relative '../../support/stub_settings_source'
require_relative '../../../sidekiq_cluster/cli'

RSpec.describe Gitlab::SidekiqCluster::CLI, :stub_settings_source, feature_category: :gitlab_cli do # rubocop:disable RSpec/SpecFilePathFormat
  include NextInstanceOf

  let(:cli) { described_class.new('/dev/null') }
  let(:timeout) { Gitlab::SidekiqCluster::DEFAULT_SOFT_TIMEOUT_SECONDS }
  let(:default_options) do
    { env: 'test', directory: Dir.pwd, dryrun: false, timeout: timeout, concurrency: 20 }
  end

  let(:sidekiq_exporter_enabled) { false }
  let(:sidekiq_exporter_port) { '3807' }

  let(:config) do
    {
      'sidekiq_exporter' => {
        'address' => 'localhost',
        'enabled' => sidekiq_exporter_enabled,
        'port' => sidekiq_exporter_port
      }
    }
  end

  let(:supervisor) { instance_double(Gitlab::SidekiqCluster::SidekiqProcessSupervisor) }
  let(:metrics_cleanup_service) { instance_double(Prometheus::CleanupMultiprocDirService, execute: nil) }

  before do
    allow(Gitlab::ProcessManagement).to receive(:write_pid)
    allow(Gitlab::SidekiqCluster::SidekiqProcessSupervisor).to receive(:instance).and_return(supervisor)
    allow(supervisor).to receive(:supervise)

    allow(Prometheus::CleanupMultiprocDirService).to receive(:new).and_return(metrics_cleanup_service)

    stub_config(sidekiq: { routing_rules: [] })
  end

  around do |example|
    original = Settings['monitoring']
    Settings['monitoring'] = config

    example.run

    Settings['monitoring'] = original
  end

  describe '#run' do
    context 'without any arguments' do
      it 'raises CommandError' do
        expect { cli.run([]) }.to raise_error(described_class::CommandError)
      end
    end

    context 'with arguments' do
      context 'with routing rules specified' do
        before do
          stub_config(sidekiq: { routing_rules: [
            ['resource_boundary=cpu', 'foo'],
            ['urgency=high', 'bar']
          ] })
        end

        it 'starts the Sidekiq workers' do
          expect(Gitlab::SidekiqCluster).to receive(:start)
                                              .with([%w[foo bar]], default_options)
                                              .and_return([])

          cli.run(%w[foo,bar])
        end

        it 'allows the special * selector' do
          expected_queues = %w[foo bar mailers]

          expect(Gitlab::SidekiqCluster)
            .to receive(:start).with([expected_queues], default_options).and_return([])

          cli.run(%w[*])
        end

        context 'with multi argument queues' do
          it 'starts with multiple queues' do
            expected_queues = [%w[foo bar mailers], %w[foo bar]]

            expect(Gitlab::SidekiqCluster)
              .to receive(:start).with(expected_queues, default_options).and_return([])

            cli.run(%w[* foo,bar])
          end
        end

        context 'with shard details in routing rules' do
          before do
            stub_config(sidekiq: { routing_rules: [['resource_boundary=cpu', 'foo', 'shard-1']] })
          end

          it 'starts the Sidekiq workers' do
            expect(Gitlab::SidekiqCluster).to receive(:start)
                                                .with([['foo']], default_options)
                                                .and_return([])

            cli.run(%w[foo])
          end
        end

        it 'raises an error when the arguments contain newlines' do
          invalid_arguments = [
            ["foo\n"],
            ["foo\r"],
            %W[foo b\nar]
          ]

          invalid_arguments.each do |arguments|
            expect { cli.run(arguments) }.to raise_error(described_class::CommandError)
          end
        end

        context 'with --concurrency flag' do
          it 'starts Sidekiq workers for specified queues with the fixed concurrency' do
            expected_queues = [%w[foo bar baz], %w[solo]]
            expect(Gitlab::SidekiqCluster).to receive(:start)
                                                .with(expected_queues, default_options.merge(concurrency: 2))
                                                .and_return([])

            cli.run(%w[foo,bar,baz solo -c 2])
          end
        end

        context 'with --timeout flag' do
          it 'when given', 'starts Sidekiq workers with given timeout' do
            expect(Gitlab::SidekiqCluster).to receive(:start)
              .with([['foo']], default_options.merge(timeout: 10))
              .and_return([])

            cli.run(%w[foo --timeout 10])
          end

          it 'when not given', 'starts Sidekiq workers with default timeout' do
            expect(Gitlab::SidekiqCluster).to receive(:start)
              .with([['foo']], default_options.merge(timeout:
                                                              Gitlab::SidekiqCluster::DEFAULT_SOFT_TIMEOUT_SECONDS))
              .and_return([])

            cli.run(%w[foo])
          end
        end

        context 'with --list-queues flag' do
          it 'errors when given --list-queues and --dryrun' do
            expect { cli.run(%w[foo --list-queues --dryrun]) }.to raise_error(described_class::CommandError)
          end

          it 'prints out a list of queues' do
            expected_queues = %w[
              bar
              baz
              default
              foo
            ]

            expect(cli).to receive(:puts).with([expected_queues])

            cli.run(%w[foo,bar,baz,default --list-queues])
          end
        end
      end

      context "without sidekiq setting specified" do
        before do
          stub_config(sidekiq: nil)
        end

        it "does not throw an error" do
          allow(Gitlab::SidekiqCluster).to receive(:start).and_return([])

          expect { cli.run(%w[foo]) }.not_to raise_error
        end

        it "starts Sidekiq workers with DEFAULT_QUEUES" do
          expect(Gitlab::SidekiqCluster).to receive(:start)
                                              .with([described_class::DEFAULT_QUEUES], default_options)
                                              .and_return([])

          cli.run(%w[foo])
        end

        context 'with multi argument queues' do
          it 'starts with multiple DEFAULT_QUEUES' do
            expected_queues = [%w[default mailers], %w[default mailers]]

            expect(Gitlab::SidekiqCluster)
              .to receive(:start).with(expected_queues, default_options).and_return([])

            cli.run(%w[* foo,bar])
          end
        end
      end

      context "without routing rules" do
        before do
          stub_config(sidekiq: { routing_rules: [] })
        end

        it "starts Sidekiq workers with DEFAULT_QUEUES" do
          expect(Gitlab::SidekiqCluster).to receive(:start)
                                              .with([described_class::DEFAULT_QUEUES], default_options)
                                              .and_return([])

          cli.run(%w[foo])
        end

        context "with 4 wildcard * as argument" do
          it "starts 4 Sidekiq workers all with DEFAULT_QUEUES" do
            expect(Gitlab::SidekiqCluster).to receive(:start)
                                                .with([described_class::DEFAULT_QUEUES] * 4, default_options)
                                                .and_return([])

            cli.run(%w[* * * *])
          end
        end
      end
    end

    context 'metrics server' do
      let(:trapped_signals) { described_class::TERMINATE_SIGNALS + described_class::FORWARD_SIGNALS }
      let(:metrics_dir) { Dir.mktmpdir }

      before do
        stub_env('prometheus_multiproc_dir', metrics_dir)
      end

      after do
        FileUtils.rm_rf(metrics_dir, secure: true)
      end

      context 'starting the server' do
        before do
          allow(Gitlab::SidekiqCluster).to receive(:start).and_return([])
        end

        context 'without --dryrun' do
          it 'wipes the metrics directory before starting workers' do
            expect(metrics_cleanup_service).to receive(:execute).ordered
            expect(Gitlab::SidekiqCluster).to receive(:start).ordered.and_return([])

            cli.run(%w[foo])
          end

          context 'when sidekiq_exporter is not set up' do
            let(:config) do
              { 'sidekiq_exporter' => {} }
            end

            it 'does not start a sidekiq metrics server' do
              expect(MetricsServer).not_to receive(:start_for_sidekiq)

              cli.run(%w[foo])
            end
          end

          context 'with missing sidekiq_exporter setting' do
            let(:config) do
              { 'sidekiq_exporter' => nil }
            end

            it 'does not start a sidekiq metrics server' do
              expect(MetricsServer).not_to receive(:start_for_sidekiq)

              cli.run(%w[foo])
            end

            it 'does not throw an error' do
              expect { cli.run(%w[foo]) }.not_to raise_error
            end
          end

          context 'when sidekiq_exporter is disabled' do
            it 'does not start a sidekiq metrics server' do
              expect(MetricsServer).not_to receive(:start_for_sidekiq)

              cli.run(%w[foo])
            end
          end

          context 'when sidekiq_exporter is enabled' do
            let(:sidekiq_exporter_enabled) { true }

            it 'starts the metrics server' do
              expect(MetricsServer).to receive(:start_for_sidekiq).with(metrics_dir: metrics_dir, reset_signals: trapped_signals)

              cli.run(%w[foo])
            end
          end

          context 'when a PID is specified' do
            it 'writes the PID to a file' do
              expect(Gitlab::ProcessManagement).to receive(:write_pid).with('/dev/null')

              cli.option_parser.parse!(%w[-P /dev/null])
              cli.run(%w[foo])
            end
          end

          context 'when no PID is specified' do
            it 'does not write a PID' do
              expect(Gitlab::ProcessManagement).not_to receive(:write_pid)

              cli.run(%w[foo])
            end
          end
        end

        context 'with --dryrun set' do
          let(:sidekiq_exporter_enabled) { true }

          it 'does not start the server' do
            expect(MetricsServer).not_to receive(:start_for_sidekiq)

            cli.run(%w[foo --dryrun])
          end
        end
      end
    end

    context 'supervising the cluster' do
      let(:sidekiq_exporter_enabled) { true }
      let(:metrics_server_pid) { 99 }
      let(:sidekiq_worker_pids) { [2, 42] }
      let(:waiter_threads) { [instance_double('Process::Waiter'), instance_double('Process::Waiter')] }
      let(:process_status) { instance_double('Process::Status') }

      before do
        allow(Gitlab::SidekiqCluster).to receive(:start).and_return(waiter_threads)
        allow(process_status).to receive(:success?).and_return(true)
        allow(cli).to receive(:exit)

        waiter_threads.each.with_index do |thread, i|
          allow(thread).to receive(:join)
          allow(thread).to receive(:pid).and_return(sidekiq_worker_pids[i])
          allow(thread).to receive(:value).and_return(process_status)
        end
      end

      context 'when one of the workers has been terminated gracefully' do
        it 'stops the entire process cluster' do
          expect(MetricsServer).to receive(:start_for_sidekiq).once.and_return(metrics_server_pid)
          expect(supervisor).to receive(:supervise).and_yield([2, 99])
          expect(supervisor).to receive(:shutdown)
          expect(cli).not_to receive(:exit).with(1)

          cli.run(%w[foo])
        end
      end

      context 'when one of the workers has failed' do
        it 'stops the entire process cluster and exits with a non-zero code' do
          expect(MetricsServer).to receive(:start_for_sidekiq).once.and_return(metrics_server_pid)
          expect(supervisor).to receive(:supervise).and_yield([2, 99])
          expect(supervisor).to receive(:shutdown)
          expect(process_status).to receive(:success?).and_return(false)
          expect(cli).to receive(:exit).with(1)

          cli.run(%w[foo])
        end
      end

      it 'stops the entire process cluster if one of the workers has been terminated' do
        expect(MetricsServer).to receive(:start_for_sidekiq).once.and_return(metrics_server_pid)
        expect(supervisor).to receive(:supervise).and_yield([2, 99])
        expect(supervisor).to receive(:shutdown)

        cli.run(%w[foo])
      end

      it 'restarts the metrics server when it is down' do
        expect(supervisor).to receive(:supervise).and_yield([metrics_server_pid])
        expect(MetricsServer).to receive(:start_for_sidekiq).twice.and_return(metrics_server_pid)

        cli.run(%w[foo])
      end
    end
  end
end
