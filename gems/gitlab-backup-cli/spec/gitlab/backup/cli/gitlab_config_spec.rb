# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::GitlabConfig do
  let(:config_fixture) { fixtures_path.join('config/gitlab.yml') }

  subject(:gitlab_config) { described_class.new(config_fixture) }

  describe '#initialize' do
    context 'when provided with a gitlab configuration file' do
      it 'loads the configuration' do
        expect(gitlab_config.keys).to include('test')
      end
    end

    context 'when provided with a filepath that does not exist' do
      let(:config_fixture) { fixtures_path.join('unknown-gitlab.yml') }

      it 'does not raise an exception', :silence_output do
        expect { gitlab_config }.not_to raise_error
        expect(gitlab_config).not_to be_loaded
      end

      it 'displays an error message' do
        expect { gitlab_config }.to output(/GitLab configuration file: .+ does not exist/).to_stderr
      end
    end

    context 'when the process lacks enough permission to read provided config file' do
      before do
        allow(ActiveSupport::ConfigurationFile).to receive(:parse).and_raise(Errno::EACCES)
      end

      it 'does not raise an exception', :silence_output do
        expect { gitlab_config }.not_to raise_error
        expect(gitlab_config).not_to be_loaded
      end

      it 'displays an error message' do
        error_message_pattern = /GitLab configuration file: .+ can't be read \(permission denied\)/
        expect { gitlab_config }.to output(error_message_pattern).to_stderr
      end
    end
  end
end
