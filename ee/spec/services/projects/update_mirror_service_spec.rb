require 'spec_helper'

describe Projects::UpdateMirrorService do
  let(:project) do
    create(:project, :repository, :mirror, import_url: Project::UNKNOWN_IMPORT_URL, only_mirror_protected_branches: false)
  end

  describe "#execute" do
    context 'unlicensed' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'does nothing' do
        expect(project).not_to receive(:fetch_mirror)

        result = described_class.new(project, project.owner).execute
        expect(result[:status]).to eq(:success)
      end
    end

    it "fetches the upstream repository" do
      expect(project).to receive(:fetch_mirror)

      described_class.new(project, project.owner).execute
    end

    it 'rescues exceptions from Repository#ff_merge' do
      stub_fetch_mirror(project)

      expect(project.repository).to receive(:ff_merge).and_raise(Gitlab::Git::PreReceiveError)

      expect { described_class.new(project, project.owner).execute }.not_to raise_error
    end

    it "succeeds" do
      stub_fetch_mirror(project)

      result = described_class.new(project, project.owner).execute

      expect(result[:status]).to eq(:success)
    end

    describe "updating tags" do
      it "creates new tags" do
        stub_fetch_mirror(project)

        described_class.new(project, project.owner).execute

        expect(project.repository.tag_names).to include('new-tag')
      end

      it "only invokes GitTagPushService for tags pointing to commits" do
        stub_fetch_mirror(project)

        expect(GitTagPushService).to receive(:new)
          .with(project, project.owner, hash_including(ref: 'refs/tags/new-tag')).and_return(double(execute: true))

        described_class.new(project, project.owner).execute
      end
    end

    describe "updating branches" do
      subject { described_class.new(project, project.owner) }

      context 'when mirror only protected branches option is set' do
        let(:new_protected_branch_name) { 'new-branch' }
        let(:protected_branch_name) { 'existing-branch' }

        before do
          project.update(only_mirror_protected_branches: true)
        end

        it 'creates a new protected branch' do
          create(:protected_branch, project: project, name: new_protected_branch_name)
          project.reload

          stub_fetch_mirror(project)

          subject.execute

          expect(project.repository.branch_names).to include(new_protected_branch_name)
        end

        it 'does not create an unprotected branch' do
          stub_fetch_mirror(project)

          described_class.new(project, project.owner).execute

          expect(project.repository.branch_names).not_to include(new_protected_branch_name)
        end

        it 'updates existing protected branches' do
          create(:protected_branch, project: project, name: protected_branch_name)
          project.reload

          stub_fetch_mirror(project)

          subject.execute

          expect(project.repository.find_branch(protected_branch_name).dereferenced_target)
            .to eq(project.repository.find_branch('master').dereferenced_target)
        end

        it "does not update unprotected branches" do
          stub_fetch_mirror(project)

          subject.execute

          expect(project.repository.find_branch(protected_branch_name).dereferenced_target)
            .not_to eq(project.repository.find_branch('master').dereferenced_target)
        end
      end

      it "creates new branches" do
        stub_fetch_mirror(project)

        subject.execute

        expect(project.repository.branch_names).to include('new-branch')
      end

      it "updates existing branches" do
        stub_fetch_mirror(project)

        subject.execute

        expect(project.repository.find_branch('existing-branch').dereferenced_target)
          .to eq(project.repository.find_branch('master').dereferenced_target)
      end

      context 'with diverged branches' do
        before do
          stub_fetch_mirror(project)
        end

        context 'when mirror_overwrites_diverged_branches is true' do
          it 'update diverged branches' do
            project.mirror_overwrites_diverged_branches = true

            subject.execute

            expect(project.repository.find_branch('markdown').dereferenced_target)
                .to eq(project.repository.find_branch('master').dereferenced_target)
          end
        end

        context 'when mirror_overwrites_diverged_branches is false' do
          it "doesn't update diverged branches" do
            project.mirror_overwrites_diverged_branches = false

            subject.execute

            expect(project.repository.find_branch('markdown').dereferenced_target)
                .not_to eq(project.repository.find_branch('master').dereferenced_target)
          end
        end

        context 'when mirror_overwrites_diverged_branches is nil' do
          it "doesn't update diverged branches" do
            project.mirror_overwrites_diverged_branches = nil

            subject.execute

            expect(project.repository.find_branch('markdown').dereferenced_target)
                .not_to eq(project.repository.find_branch('master').dereferenced_target)
          end
        end
      end

      describe 'when project is empty' do
        let(:project) { create(:project_empty_repo, :mirror, import_url: Project::UNKNOWN_IMPORT_URL) }

        it 'does not add a default master branch' do
          repository = project.repository

          allow(project).to receive(:fetch_mirror) { create_file(repository) }
          expect(CreateBranchService).not_to receive(:create_master_branch)

          subject.execute

          expect(repository.branch_names).not_to include('master')
        end
      end

      def create_file(repository)
        repository.create_file(
          project.owner,
          '/newfile.txt',
          'hello',
          message: 'Add newfile.txt',
          branch_name: 'newbranch'
        )
      end
    end

    describe "when the mirror user doesn't have access" do
      it "fails" do
        stub_fetch_mirror(project)

        result = described_class.new(project, create(:user)).execute

        expect(result[:status]).to eq(:error)
      end
    end

    describe "when no user is present" do
      it "fails" do
        result = described_class.new(project, nil).execute

        expect(result[:status]).to eq(:error)
      end
    end

    describe "when is no mirror" do
      let(:project) { build_stubbed(:project) }

      it "success" do
        expect(project.mirror?).to eq(false)

        result = described_class.new(project, create(:user)).execute

        expect(result[:status]).to eq(:success)
      end
    end
  end

  def stub_fetch_mirror(project, repository: project.repository)
    allow(project).to receive(:fetch_mirror) { fetch_mirror(repository) }
  end

  def fetch_mirror(repository)
    rugged = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
      repository.rugged
    end
    masterrev = repository.find_branch('master').dereferenced_target.id

    parentrev = repository.commit(masterrev).parent_id
    rugged.references.create('refs/heads/existing-branch', parentrev)

    repository.expire_branches_cache
    repository.branches

    # New branch
    rugged.references.create('refs/remotes/upstream/new-branch', masterrev)

    # Updated existing branch
    rugged.references.create('refs/remotes/upstream/existing-branch', masterrev)

    # Diverged branch
    rugged.references.create('refs/remotes/upstream/markdown', masterrev)

    # New tag
    rugged.references.create('refs/tags/new-tag', masterrev)

    # New tag that point to a blob
    rugged.references.create('refs/tags/new-tag-on-blob', 'c74175afd117781cbc983664339a0f599b5bb34e')
  end
end
