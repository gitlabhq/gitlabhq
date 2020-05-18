# frozen_string_literal: true

describe QA::Git::Repository do
  include Helpers::StubENV

  shared_context 'unresolvable git directory' do
    let(:repo_uri) { 'http://foo/bar.git' }
    let(:repo_uri_with_credentials) { 'http://root@foo/bar.git' }
    let(:repository) { described_class.new.tap { |r| r.uri = repo_uri } }
    let(:tmp_git_dir) { Dir.mktmpdir }
    let(:tmp_netrc_dir) { Dir.mktmpdir }

    before do
      stub_env('GITLAB_USERNAME', 'root')
      allow(repository).to receive(:tmp_home_dir).and_return(tmp_netrc_dir)
    end

    around do |example|
      FileUtils.cd(tmp_git_dir) do
        example.run
      end
    end

    after do
      FileUtils.remove_entry_secure(tmp_git_dir, true)
      FileUtils.remove_entry_secure(tmp_netrc_dir, true)
    end
  end

  shared_examples 'command with retries' do
    let(:extra_args) { {} }
    let(:result_output) { +'Command successful' }
    let(:result) { described_class::Result.new(any_args, 0, result_output) }
    let(:command_return) { result_output }

    context 'when command is successful' do
      it 'returns the #run command Result output' do
        expect(repository).to receive(:run).with(command, extra_args.merge(max_attempts: 3)).and_return(result)

        expect(call_method).to eq(command_return)
      end
    end

    context 'when command is not successful the first time' do
      context 'and retried command is successful' do
        it 'retries the command twice and returns the successful #run command Result output' do
          expect(Open3).to receive(:capture2e).and_return([+'', double(exitstatus: 1)]).twice
          expect(Open3).to receive(:capture2e).and_return([result_output, double(exitstatus: 0)])

          expect(call_method).to eq(command_return)
        end
      end

      context 'and retried command is not successful after 3 attempts' do
        it 'raises a RepositoryCommandError exception' do
          expect(Open3).to receive(:capture2e).and_return([+'FAILURE', double(exitstatus: 42)]).exactly(3).times

          expect { call_method }.to raise_error(described_class::RepositoryCommandError, /The command .* failed \(42\) with the following output:\nFAILURE/)
        end
      end
    end
  end

  context 'with default credentials' do
    include_context 'unresolvable git directory' do
      before do
        repository.use_default_credentials
      end
    end

    describe '#clone' do
      let(:opts) { '' }
      let(:call_method) { repository.clone }
      let(:command) { "git clone #{opts} #{repo_uri_with_credentials} ./" }

      context 'when no opts is given' do
        it_behaves_like 'command with retries'
      end

      context 'when opts is given' do
        let(:opts) { '--depth 1' }

        it_behaves_like 'command with retries' do
          let(:call_method) { repository.clone(opts) }
        end
      end
    end

    describe '#shallow_clone' do
      it_behaves_like 'command with retries' do
        let(:call_method) { repository.shallow_clone }
        let(:command) { "git clone --depth 1 #{repo_uri_with_credentials} ./" }
      end
    end

    describe '#delete_tag' do
      it_behaves_like 'command with retries' do
        let(:tag_name) { 'v1.0' }
        let(:call_method) { repository.delete_tag(tag_name) }
        let(:command) { "git push origin --delete #{tag_name}" }
      end
    end

    describe '#push_changes' do
      let(:branch) { 'master' }
      let(:call_method) { repository.push_changes }
      let(:command) { "git push #{repo_uri_with_credentials} #{branch}" }

      context 'when no branch is given' do
        it_behaves_like 'command with retries'
      end

      context 'when branch is given' do
        let(:branch) { 'my-branch' }

        it_behaves_like 'command with retries' do
          let(:call_method) { repository.push_changes(branch) }
        end
      end
    end

    describe '#git_protocol=' do
      [0, 1, 2].each do |version|
        it "configures git to use protocol version #{version}" do
          expect(repository).to receive(:run).with("git config protocol.version #{version}")

          repository.git_protocol = version
        end
      end

      it 'raises an error if the version is unsupported' do
        expect { repository.git_protocol = 'foo' }.to raise_error(ArgumentError, "Please specify the protocol you would like to use: 0, 1, or 2")
      end
    end

    describe '#fetch_supported_git_protocol' do
      let(:call_method) { repository.fetch_supported_git_protocol }

      it_behaves_like 'command with retries' do
        let(:command) { "git ls-remote #{repo_uri_with_credentials}" }
        let(:result_output) { +'packet: git< version 2' }
        let(:command_return) { '2' }
        let(:extra_args) { { env: "GIT_TRACE_PACKET=1" } }
      end

      it "reports the detected version" do
        expect(repository).to receive(:run).and_return(described_class::Result.new(any_args, 0, "packet: git< version 2"))

        expect(call_method).to eq('2')
      end

      it 'reports unknown if version is unknown' do
        expect(repository).to receive(:run).and_return(described_class::Result.new(any_args, 0, "packet: git< version -1"))

        expect(call_method).to eq('unknown')
      end

      it 'reports unknown if content does not identify a version' do
        expect(repository).to receive(:run).and_return(described_class::Result.new(any_args, 0, "foo"))

        expect(call_method).to eq('unknown')
      end
    end

    describe '#use_default_credentials' do
      it 'adds credentials to .netrc' do
        expect(File.read(File.join(tmp_netrc_dir, '.netrc')))
          .to eq("machine foo login #{QA::Runtime::User.default_username} password #{QA::Runtime::User.default_password}\n")
      end
    end
  end

  context 'with specific credentials' do
    include_context 'unresolvable git directory'

    context 'before setting credentials' do
      it 'does not add credentials to .netrc' do
        expect(repository).not_to receive(:save_netrc_content)
      end
    end

    describe '#password=' do
      it 'raises an error if no username was given' do
        expect { repository.password = 'foo' }
          .to raise_error(QA::Git::Repository::InvalidCredentialsError,
            "Please provide a username when setting a password")
      end

      it 'adds credentials to .netrc' do
        repository.username = 'user'
        repository.password = 'foo'

        expect(File.read(File.join(tmp_netrc_dir, '.netrc')))
          .to eq("machine foo login user password foo\n")
      end

      it 'adds credentials with special characters' do
        password = %q[!"#$%&')(*+,-./:;<=>?]
        repository.username = 'user'
        repository.password = password

        expect(File.read(File.join(tmp_netrc_dir, '.netrc')))
          .to eq("machine foo login user password #{password}\n")
      end
    end
  end
end
