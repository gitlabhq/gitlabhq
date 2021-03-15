# frozen_string_literal: true

RSpec.describe QA::Support::SSH do
  let(:key) { Struct.new(:private_key).new('private_key') }
  let(:known_hosts_file) { Tempfile.new('known_hosts_file') }
  let(:private_key_file) { Tempfile.new('private_key_file') }
  let(:result) { QA::Support::Run::Result.new('', 0, '') }

  let(:ssh) do
    described_class.new.tap do |ssh|
      ssh.uri = uri
      ssh.key = key
      ssh.private_key_file = private_key_file
      ssh.known_hosts_file = known_hosts_file
    end
  end

  shared_examples 'providing correct ports' do
    context 'when no port specified in uri' do
      let(:uri) { 'http://foo.com' }

      it 'does not provide port in ssh command' do
        expect(ssh).to receive(:run).with(expected_ssh_command_no_port, any_args).and_return(result)

        call_method
      end
    end

    context 'when no port specified in https uri' do
      let(:uri) { 'https://foo.com' }

      it 'does not provide port in ssh command' do
        expect(ssh).to receive(:run).with(expected_ssh_command_no_port, any_args).and_return(result)

        call_method
      end
    end

    context 'when port 80 specified in uri' do
      let(:uri) { 'http://foo.com:80' }

      it 'does not provide port in ssh command' do
        expect(ssh).to receive(:run).with(expected_ssh_command_no_port, any_args).and_return(result)

        call_method
      end
    end

    context 'when other port is specified in uri' do
      let(:port) { 1234 }
      let(:uri) { "http://foo.com:#{port}" }

      it "provides other port in ssh command" do
        expect(ssh).to receive(:run).with(expected_ssh_command_port, any_args).and_return(result)

        call_method
      end
    end
  end

  describe '#setup' do
    let(:expected_ssh_command_no_port) { "ssh-keyscan -H foo.com >> #{known_hosts_file.path}" }
    let(:expected_ssh_command_port) { "ssh-keyscan -H -p #{port} foo.com >> #{known_hosts_file.path}" }
    let(:call_method) { ssh.setup }

    before do
      allow(File).to receive(:binwrite).with(private_key_file, key.private_key)
      allow(File).to receive(:chmod).with(0700, private_key_file)
    end

    it_behaves_like 'providing correct ports'
  end

  describe '#reset_2fa_codes' do
    let(:expected_ssh_command_no_port) { "echo yes | ssh -i #{private_key_file.path} -o UserKnownHostsFile=#{known_hosts_file.path} git@foo.com 2fa_recovery_codes" }
    let(:expected_ssh_command_port) { "echo yes | ssh -i #{private_key_file.path} -o UserKnownHostsFile=#{known_hosts_file.path} git@foo.com -p #{port} 2fa_recovery_codes" }
    let(:call_method) { ssh.reset_2fa_codes }

    before do
      allow(ssh).to receive(:git_user).and_return('git')
    end

    it_behaves_like 'providing correct ports'
  end

  describe '#git_user' do
    context 'when running on CI' do
      let(:uri) { 'http://gitlab.com' }

      before do
        allow(QA::Runtime::Env).to receive(:running_in_ci?).and_return(true)
      end

      it 'returns git user' do
        expect(ssh.send(:git_user)).to eq('git')
      end
    end

    context 'when running on a review app in CI' do
      let(:uri) { 'https://gitlab-review.app' }

      before do
        allow(QA::Runtime::Env).to receive(:running_in_ci?).and_return(true)
      end

      it 'returns git user' do
        expect(ssh.send(:git_user)).to eq('git')
      end
    end

    context 'when running against environment on a port other than 80 or 443' do
      let(:uri) { 'http://localhost:3000' }

      before do
        allow(Etc).to receive(:getlogin).and_return('dummy_username')
        allow(QA::Runtime::Env).to receive(:running_in_ci?).and_return(false)
      end

      it 'returns the local user' do
        expect(ssh.send(:git_user)).to eq('dummy_username')
      end
    end

    context 'when running against environment on port 80 and not on CI (docker)' do
      let(:uri) { 'http://localhost' }

      before do
        allow(QA::Runtime::Env).to receive(:running_in_ci?).and_return(false)
      end

      it 'returns git user' do
        expect(ssh.send(:git_user)).to eq('git')
      end
    end
  end
end
