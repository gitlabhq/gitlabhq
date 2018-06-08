describe QA::Git::Repository do
  let(:repository) { described_class.new }

  before do
    cd_empty_temp_directory
    set_bad_uri
    repository.use_default_credentials
  end

  describe '#clone' do
    it 'redacts credentials from the URI in output' do
      output, _ = repository.clone

      expect(output).to include("fatal: unable to access 'http://****@foo/bar.git/'")
    end
  end

  describe '#push_changes' do
    before do
      `git init` # need a repo to push from
    end

    it 'redacts credentials from the URI in output' do
      output, _ = repository.push_changes

      expect(output).to include("error: failed to push some refs to 'http://****@foo/bar.git'")
    end
  end

  def cd_empty_temp_directory
    tmp_dir = 'tmp/git-repository-spec/'
    FileUtils.rm_r(tmp_dir) if File.exist?(tmp_dir)
    FileUtils.mkdir_p tmp_dir
    FileUtils.cd tmp_dir
  end

  def set_bad_uri
    repository.uri = 'http://foo/bar.git'
  end
end
