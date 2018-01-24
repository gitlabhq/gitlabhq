require 'spec_helper'
require 'rake_helper'

describe SystemCheck::Geo::AuthorizedKeysCheck do
  describe '#multi_check' do
    subject { described_class.new }

    before do
      allow(File).to receive(:file?).and_call_original # provides a default behavior when mocking
      allow(File).to receive(:file?).with('/opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-keys-check') { true }
    end

    context 'OpenSSH config file' do
      context 'in docker' do
        it 'fails when config file does not exist' do
          allow(subject).to receive(:in_docker?) { true }
          allow(File).to receive(:file?).with('/assets/sshd_config') { false }

          expect_failure('Cannot find OpenSSH configuration file at: /assets/sshd_config')

          subject.multi_check
        end
      end

      it 'fails when config file does not exist' do
        allow(subject).to receive(:in_docker?) { false }
        allow(File).to receive(:file?).with('/etc/ssh/sshd_config') { false }

        expect_failure('Cannot find OpenSSH configuration file at: /etc/ssh/sshd_config')

        subject.multi_check
      end

      it 'skips when config file is not readable' do
        override_sshd_config('system_check/sshd_config')
        allow(File).to receive(:readable?).with(expand_fixture_ee_path('system_check/sshd_config')) { false }

        expect_skipped('Cannot access OpenSSH configuration file')

        subject.multi_check
      end
    end

    context 'AuthorizedKeysCommand' do
      it 'fails when config file does not contain the AuthorizedKeysCommand' do
        override_sshd_config('system_check/sshd_config_no_command')

        expect_failure('OpenSSH configuration file does not contain a AuthorizedKeysCommand')

        subject.multi_check
      end

      it 'warns when config file does not contain the correct AuthorizedKeysCommand' do
        override_sshd_config('system_check/sshd_config_invalid_command')

        expect_warning('OpenSSH configuration file points to a different AuthorizedKeysCommand')

        subject.multi_check
      end

      it 'fails when cannot find referred authorized keys file on disk' do
        override_sshd_config('system_check/sshd_config')
        allow(subject).to receive(:extract_authorized_keys_command) { '/tmp/nonexistent/authorized_keys' }

        expect_failure('Cannot find configured AuthorizedKeysCommand: /tmp/nonexistent/authorized_keys')

        subject.multi_check
      end
    end

    context 'AuthorizedKeysCommandUser' do
      it 'fails when config file does not contain the AuthorizedKeysCommandUser' do
        override_sshd_config('system_check/sshd_config_no_user')

        expect_failure('OpenSSH configuration file does not contain a AuthorizedKeysCommandUser')

        subject.multi_check
      end

      it 'fails when config file does not contain the correct AuthorizedKeysCommandUser' do
        override_sshd_config('system_check/sshd_config_invalid_user')

        expect_warning('OpenSSH configuration file points to a different AuthorizedKeysCommandUser')

        subject.multi_check
      end
    end

    it 'succeed when all conditions are met' do
      override_sshd_config('system_check/sshd_config')
      allow(subject).to receive(:gitlab_user) { 'git' }

      result = subject.multi_check
      expect($stdout.string).to include('yes')
      expect(result).to be_truthy
    end
  end

  describe '#extract_authorized_keys_command' do
    it 'returns false when no command is available' do
      override_sshd_config('system_check/sshd_config_no_command')

      expect(subject.extract_authorized_keys_command).to be_falsey
    end

    it 'returns correct (uncommented) command' do
      override_sshd_config('system_check/sshd_config')

      expect(subject.extract_authorized_keys_command).to eq('/opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-keys-check %u %k')
    end

    it 'returns command without comments and without quotes' do
      override_sshd_config('system_check/sshd_config_invalid_command')

      expect(subject.extract_authorized_keys_command).to eq('/opt/gitlab-shell/invalid_authorized_keys   %u      %k')
    end
  end

  describe '#extract_authorized_keys_command_user' do
    it 'returns false when no command user is available' do
      override_sshd_config('system_check/sshd_config_no_command')

      expect(subject.extract_authorized_keys_command_user).to be_falsey
    end

    it 'returns correct (uncommented) command' do
      override_sshd_config('system_check/sshd_config')

      expect(subject.extract_authorized_keys_command_user).to eq('git')
    end

    it 'returns command without comments' do
      override_sshd_config('system_check/sshd_config_invalid_command')

      expect(subject.extract_authorized_keys_command_user).to eq('anotheruser')
    end
  end

  describe '#openssh_config_path' do
    context 'when in docker container' do
      it 'returns /assets/sshd_config' do
        allow(subject).to receive(:in_docker?) { true }

        expect(subject.openssh_config_path).to eq('/assets/sshd_config')
      end
    end

    context 'when not in docker container' do
      it 'returns /etc/ssh/sshd_config' do
        allow(subject).to receive(:in_docker?) { false }

        expect(subject.openssh_config_path).to eq('/etc/ssh/sshd_config')
      end
    end
  end

  def expect_failure(reason)
    expect(subject).to receive(:print_failure).with(reason)
  end

  def expect_warning(reason)
    expect(subject).to receive(:print_warning).with(reason)
  end

  def expect_skipped(reason)
    expect(subject).to receive(:print_skipped).with(reason)
  end

  def override_sshd_config(relative_path)
    allow(subject).to receive(:openssh_config_path) { expand_fixture_ee_path(relative_path) }
  end
end
