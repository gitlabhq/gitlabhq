require 'spec_helper'

describe Repository do
  include RepoHelpers
  include ::EE::GeoHelpers
  TestBlob = Struct.new(:path)

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

  def create_remote_branch(remote_name, branch_name, target)
    rugged = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
      repository.rugged
    end
    rugged.references.create("refs/remotes/#{remote_name}/#{branch_name}", target.id)
  end

  describe '#after_sync' do
    it 'expires repository cache' do
      expect(repository).to receive(:expire_all_method_caches)
      expect(repository).to receive(:expire_branch_cache)
      expect(repository).to receive(:expire_content_cache)

      repository.after_sync
    end

    it 'does not call expire_branch_cache if repository does not exist' do
      allow(repository).to receive(:exists?).and_return(false)

      expect(repository).to receive(:expire_all_method_caches)
      expect(repository).not_to receive(:expire_branch_cache)
      expect(repository).to receive(:expire_content_cache)

      repository.after_sync
    end
  end

  describe '#with_config' do
    let(:rugged) do
      Gitlab::GitalyClient::StorageSettings.allow_disk_access do
        repository.rugged
      end
    end
    let(:entries) do
      {
        'test.foo1' => 'hello',
        'test.foo2' => 'world',
        'http.http://gitlab-primary.geo/gitlab-qa-sandbox-group/qa-test-10-07-2018-07-22-41/geo-project-ac55ec2cd134afea.wiki.git.extraHeader' => 'Authorization: blabla'
      }
    end

    it 'sets config only during the block' do
      keys_should_not_be_set

      repository.with_config(entries) do
        entries.each do |key, value|
          expect(rugged.config[key]).to eq(value)
        end
      end

      keys_should_not_be_set
    end

    def keys_should_not_be_set
      entries.each do |key, value|
        expect(rugged.config[key]).to be_blank
      end
    end
  end

  describe "Elastic search", :elastic do
    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    end

    describe "class method find_commits_by_message_with_elastic" do
      it "returns commits" do
        project = create :project, :repository
        project1 = create :project, :repository

        project.repository.index_commits
        project1.repository.index_commits

        Gitlab::Elastic::Helper.refresh_index

        expect(described_class.find_commits_by_message_with_elastic('initial').first).to be_a(Commit)
        expect(described_class.find_commits_by_message_with_elastic('initial').count).to eq(2)
        expect(described_class.find_commits_by_message_with_elastic('initial').total_count).to eq(2)
      end
    end

    describe "find_commits_by_message_with_elastic" do
      it "returns commits" do
        project = create :project, :repository

        project.repository.index_commits

        Gitlab::Elastic::Helper.refresh_index

        expect(project.repository.find_commits_by_message_with_elastic('initial').first).to be_a(Commit)
        expect(project.repository.find_commits_by_message_with_elastic('initial').count).to eq(1)
        expect(project.repository.find_commits_by_message_with_elastic('initial').total_count).to eq(1)
      end
    end
  end

  describe '#upstream_branches' do
    it 'returns branches from the upstream remote' do
      masterrev = repository.find_branch('master').dereferenced_target
      create_remote_branch('upstream', 'upstream_branch', masterrev)

      expect(repository.upstream_branches.size).to eq(1)
      expect(repository.upstream_branches.first).to be_an_instance_of(Gitlab::Git::Branch)
      expect(repository.upstream_branches.first.name).to eq('upstream_branch')
    end
  end

  describe '#keep_around' do
    set(:primary_node)   { create(:geo_node, :primary) }
    set(:secondary_node) { create(:geo_node) }
    let(:sha) { sample_commit.id }

    context 'on a Geo primary' do
      before do
        stub_current_geo_node(primary_node)
      end

      context 'when a single SHA is passed' do
        it 'creates a RepositoryUpdatedEvent' do
          expect do
            repository.keep_around(sha)
          end.to change { ::Geo::RepositoryUpdatedEvent.count }.by(1)
        end
      end

      context 'when multiple SHAs are passed' do
        it 'creates exactly one RepositoryUpdatedEvent' do
          expect do
            repository.keep_around(sha, sample_big_commit.id)
          end.to change { ::Geo::RepositoryUpdatedEvent.count }.by(1)
        end
      end
    end

    context 'on a Geo secondary' do
      before do
        stub_current_geo_node(secondary_node)
      end

      it 'does not create a RepositoryUpdatedEvent' do
        expect do
          repository.keep_around(sha)
        end.not_to change { ::Geo::RepositoryUpdatedEvent.count }
      end
    end
  end
end
