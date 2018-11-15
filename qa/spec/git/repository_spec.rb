describe QA::Git::Repository do
  include Support::StubENV

  let(:repository) { described_class.new }

  before do
    stub_env('GITLAB_USERNAME', 'root')
    cd_empty_temp_directory
    set_bad_uri
    repository.use_default_credentials
  end

  describe '#clone' do
    it 'is unable to resolve host' do
      expect(repository.clone).to include("fatal: unable to access 'http://root@foo/bar.git/'")
    end
  end

  describe '#push_changes' do
    before do
      `git init` # need a repo to push from
    end

    it 'fails to push changes' do
      expect(repository.push_changes).to include("error: failed to push some refs to 'http://root@foo/bar.git'")
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
    it "reports the detected version" do
      expect(repository).to receive(:run).and_return("packet: git< version 2")
      expect(repository.fetch_supported_git_protocol).to eq('2')
    end

    it 'reports unknown if version is unknown' do
      expect(repository).to receive(:run).and_return("packet: git< version -1")
      expect(repository.fetch_supported_git_protocol).to eq('unknown')
    end

    it 'reports unknown if content does not identify a version' do
      expect(repository).to receive(:run).and_return("foo")
      expect(repository.fetch_supported_git_protocol).to eq('unknown')
    end
  end

  def cd_empty_temp_directory
    tmp_dir = 'tmp/git-repository-spec/'
    FileUtils.rm_rf(tmp_dir) if ::File.exist?(tmp_dir)
    FileUtils.mkdir_p tmp_dir
    FileUtils.cd tmp_dir
  end

  def set_bad_uri
    repository.uri = 'http://foo/bar.git'
  end
end
