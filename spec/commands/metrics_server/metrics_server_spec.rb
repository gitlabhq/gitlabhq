# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../metrics_server/metrics_server'

# End-to-end tests for the metrics server process we use to serve metrics
# from forking applications (Sidekiq, Puma) to the Prometheus scraper.
RSpec.describe 'GitLab metrics server', :aggregate_failures do
  let(:config_file) { Tempfile.new('gitlab.yml') }
  let(:address) { '127.0.0.1' }
  let(:port) { 3807 }
  let(:config) do
    {
      'test' => {
        'monitoring' => {
          'web_exporter' => {
            'address' => address,
            'enabled' => true,
            'port' => port
          },
          'sidekiq_exporter' => {
            'address' => address,
            'enabled' => true,
            'port' => port
          }
        }
      }
    }
  end

  shared_examples 'serves metrics endpoint' do
    it 'serves /metrics endpoint' do
      start_server!

      expect do
        Timeout.timeout(10) do
          http_ok = false
          until http_ok
            sleep 1
            response = Gitlab::HTTP.try_get("http://#{address}:#{port}/metrics", allow_local_requests: true)
            http_ok = response&.success?
          end
        end
      end.not_to raise_error
    end
  end

  shared_examples 'spawns a server' do |target|
    context "targeting #{target}" do
      let(:metrics_dir) { Dir.mktmpdir }

      subject(:start_server!) do
        @pid = MetricsServer.spawn(target, metrics_dir: metrics_dir)
      end

      before do
        config_file.write(YAML.dump(config))
        config_file.close
        stub_env('GITLAB_CONFIG', config_file.path)
        # We need to send a request to localhost
        WebMock.allow_net_connect!
      end

      after do
        webmock_enable!

        if @pid
          pgrp = Process.getpgid(@pid)

          Timeout.timeout(10) do
            Process.kill('TERM', -pgrp)
            Process.waitpid(@pid)
          end

          expect(Gitlab::ProcessManagement.process_alive?(@pid)).to be(false)
        end
      rescue Errno::ESRCH, Errno::ECHILD => _
        # 'No such process' or 'No child processes' means the process died before
      ensure
        config_file.unlink
        FileUtils.rm_rf(metrics_dir, secure: true)
      end

      it_behaves_like 'serves metrics endpoint'

      context 'when using Pathname instance as target directory' do
        let(:metrics_dir) { Pathname.new(Dir.mktmpdir) }

        it_behaves_like 'serves metrics endpoint'
      end
    end
  end

  it_behaves_like 'spawns a server', 'puma'
  it_behaves_like 'spawns a server', 'sidekiq'
end
