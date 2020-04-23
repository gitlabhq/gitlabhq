# frozen_string_literal: true

describe QA::Git::Repository do
  include Helpers::StubENV

  shared_context 'git directory' do
    let(:repository) { described_class.new }
    let(:tmp_git_dir) { Dir.mktmpdir }
    let(:tmp_netrc_dir) { Dir.mktmpdir }

    before do
      stub_env('GITLAB_USERNAME', 'root')
      cd_empty_temp_directory
      set_bad_uri

      allow(repository).to receive(:tmp_home_dir).and_return(tmp_netrc_dir)
    end

    after do
      # Switch to a safe dir before deleting tmp dirs to avoid dir access errors
      FileUtils.cd __dir__
      FileUtils.remove_entry_secure(tmp_git_dir, true)
      FileUtils.remove_entry_secure(tmp_netrc_dir, true)
    end

    def cd_empty_temp_directory
      FileUtils.cd tmp_git_dir
    end

    def set_bad_uri
      repository.uri = 'http://foo/bar.git'
    end
  end

  context 'with default credentials' do
    include_context 'git directory' do
      before do
        repository.use_default_credentials
      end
    end

    describe '#clone' do
      it 'is unable to resolve host' do
        expect { repository.clone }.to raise_error(described_class::RepositoryCommandError, /The command .* failed \(128\) with the following output/)
      end
    end

    describe '#push_changes' do
      before do
        `git init` # need a repo to push from
      end

      it 'fails to push changes' do
        expect { repository.push_changes }.to raise_error(described_class::RepositoryCommandError, /The command .* failed \(1\) with the following output/)
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
      result = Struct.new(:response)

      it "reports the detected version" do
        expect(repository).to receive(:run).and_return(result.new("packet: git< version 2"))
        expect(repository.fetch_supported_git_protocol).to eq('2')
      end

      it 'reports unknown if version is unknown' do
        expect(repository).to receive(:run).and_return(result.new("packet: git< version -1"))
        expect(repository.fetch_supported_git_protocol).to eq('unknown')
      end

      it 'reports unknown if content does not identify a version' do
        expect(repository).to receive(:run).and_return(result.new("foo"))
        expect(repository.fetch_supported_git_protocol).to eq('unknown')
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
    include_context 'git directory'

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
