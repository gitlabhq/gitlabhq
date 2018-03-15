require 'spec_helper'

describe Repository do
  include RepoHelpers
  TestBlob = Struct.new(:path)

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

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
end
