# frozen_string_literal: true

RSpec.describe QA::Git::Repository do
  shared_context 'unresolvable git directory' do
    let(:logger) { instance_double(Logger, info: nil, debug: nil) }
    let(:default_user) { QA::Resource::User.new }
    let(:repo_uri) { 'http://foo/bar.git' }
    let(:repo_uri_with_credentials) { "http://#{default_user.username}@foo/bar.git" }
    let(:env_vars) { [%q(HOME="temp")] }
    let(:extra_env_vars) { [] }
    let(:run_params) { { raise_on_failure: true, env: env_vars + extra_env_vars, sleep_internal: 0, log_prefix: "Git: " } }
    let(:repository) do
      described_class.new(command_retry_sleep_interval: 0).tap do |r|
        r.uri = repo_uri
        r.env_vars = env_vars
      end
    end

    let(:tmp_git_dir) { Dir.mktmpdir }
    let(:tmp_netrc_dir) { Dir.mktmpdir }

    before do
      allow(repository).to receive(:tmp_home_dir).and_return(tmp_netrc_dir)
      allow(QA::Runtime::Logger).to receive(:logger).and_return(logger)
      allow(QA::Runtime::User::Store).to receive(:test_user).and_return(default_user)
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
    let(:result_output) { +'Command successful' }
    let(:result) { described_class::Result.new(any_args, 0, result_output) }
    let(:command_return) { result_output }

    context 'when command is successful' do
      it 'returns the #run command Result output' do
        expect(repository).to receive(:run).with(command, run_params.merge(max_attempts: 3)).and_return(result)

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
        it 'raises a CommandError exception' do
          expect(Open3).to receive(:capture2e).and_return([+'FAILURE', double(exitstatus: 42)]).exactly(3).times

          expect do
            call_method
          end.to raise_error(QA::Support::Run::CommandError,
            /The command .* failed \(42\) with the following output:\nFAILURE/)
        end
      end
    end
  end

  shared_examples 'command with no retries' do
    let(:result_output) { +'Command successful' }
    let(:result) { described_class::Result.new(any_args, 0, result_output) }
    let(:command_return) { result_output }

    context 'when command is successful' do
      it 'returns the #run command Result output' do
        expect(repository).to receive(:run).with(command, run_params.merge(max_attempts: 1)).and_return(result)

        expect(call_method).to eq(command_return)
      end
    end

    context 'when command is not successful' do
      it 'raises a CommandError exception' do
        expect(Open3).to receive(:capture2e).and_return([+'FAILURE', double(exitstatus: 42)]).once

        expect do
          call_method
        end.to raise_error(QA::Support::Run::CommandError,
          /The command .* failed \(42\) with the following output:\nFAILURE/)
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
      let(:branch) { QA::Runtime::Env.default_branch }
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

      context 'when max_attempts is exactly 1' do
        it_behaves_like 'command with no retries' do
          let(:call_method) { repository.push_changes(max_attempts: 1) }
        end
      end

      context 'with push options' do
        let(:command) { "git push #{push_options} #{repo_uri_with_credentials} #{branch}" }

        context 'when set to create a merge request' do
          it_behaves_like 'command with retries' do
            let(:push_options) { '-o merge_request.create' }
            let(:call_method) { repository.push_changes(push_options: { create: true }) }
          end
        end

        context 'when set to merge when pipeline succeeds' do
          it_behaves_like 'command with retries' do
            let(:push_options) { '-o merge_request.merge_when_pipeline_succeeds' }
            let(:call_method) { repository.push_changes(push_options: { merge_when_pipeline_succeeds: true }) }
          end
        end

        context 'when set to remove source branch' do
          it_behaves_like 'command with retries' do
            let(:push_options) { '-o merge_request.remove_source_branch' }
            let(:call_method) { repository.push_changes(push_options: { remove_source_branch: true }) }
          end
        end

        context 'when title is given' do
          it_behaves_like 'command with retries' do
            let(:push_options) { '-o merge_request.title="Is A Title"' }
            let(:call_method) { repository.push_changes(push_options: { title: 'Is A Title' }) }
          end
        end

        context 'when description is given' do
          it_behaves_like 'command with retries' do
            let(:push_options) { '-o merge_request.description="Is A Description"' }
            let(:call_method) { repository.push_changes(push_options: { description: 'Is A Description' }) }
          end
        end

        context 'when target branch is given' do
          it_behaves_like 'command with retries' do
            let(:push_options) { '-o merge_request.target="is-a-target-branch"' }
            let(:call_method) { repository.push_changes(push_options: { target: 'is-a-target-branch' }) }
          end
        end

        context 'when a label is given' do
          it_behaves_like 'command with retries' do
            let(:push_options) { '-o merge_request.label="is-a-label"' }
            let(:call_method) { repository.push_changes(push_options: { label: ['is-a-label'] }) }
          end
        end

        context 'when two labels are given' do
          it_behaves_like 'command with retries' do
            let(:push_options) { '-o merge_request.label="is-a-label" -o merge_request.label="is-another-label"' }
            let(:call_method) { repository.push_changes(push_options: { label: %w[is-a-label is-another-label] }) }
          end
        end
      end
    end

    describe '#git_protocol=' do
      [0, 1, 2].each do |version|
        it "configures git to use protocol version #{version}" do
          expect(repository).to receive(:run).with("git config protocol.version #{version}",
            run_params.merge(max_attempts: 1))

          repository.git_protocol = version
        end
      end

      it 'raises an error if the version is unsupported' do
        expect do
          repository.git_protocol = 'foo'
        end.to raise_error(ArgumentError,
          "Please specify the protocol you would like to use: 0, 1, or 2")
      end
    end

    describe '#fetch_supported_git_protocol' do
      let(:call_method) { repository.fetch_supported_git_protocol }

      it_behaves_like 'command with retries' do
        let(:command) { "git ls-remote #{repo_uri_with_credentials}" }
        let(:result_output) { +'packet: ls-remote< version 2' }
        let(:command_return) { '2' }
        let(:extra_env_vars) { ["GIT_TRACE_PACKET=1"] }
      end

      it "reports the detected version" do
        expect(repository).to receive(:run).and_return(described_class::Result.new(any_args, 0,
          "packet: ls-remote< version 2"))

        expect(call_method).to eq('2')
      end

      it 'reports unknown if version is unknown' do
        expect(repository).to receive(:run).and_return(described_class::Result.new(any_args, 0,
          "packet: ls-remote< version -1"))

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
          .to eq("machine foo login #{default_user.username} password #{default_user.password}\n")
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
