require 'spec_helper'

describe Gitlab::Elastic::ProjectSearchResults do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:query) { 'hello world' }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    Gitlab::Elastic::Helper.create_empty_index
  end

  after do
    Gitlab::Elastic::Helper.delete_index
    stub_ee_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  describe 'initialize with empty ref' do
    subject(:results) { described_class.new(user, query, project.id, '') }

    it { expect(results.project).to eq(project) }
    it { expect(results.repository_ref).to eq('master') }
    it { expect(results.query).to eq('hello world') }
  end

  describe 'initialize with ref' do
    let(:ref) { 'refs/heads/test' }
    subject(:results) { described_class.new(user, query, project.id, ref) }

    it { expect(results.project).to eq(project) }
    it { expect(results.repository_ref).to eq(ref) }
    it { expect(results.query).to eq('hello world') }
  end

  describe "search" do
    it "returns correct amounts" do
      project = create :project, :public, :repository, :wiki_repo
      project1 = create :project, :public, :repository, :wiki_repo

      project.repository.index_blobs
      project.repository.index_commits

      # Notes
      create :note, note: 'bla-bla term', project: project
      # The note in the project you have no access to
      create :note, note: 'bla-bla term', project: project1

      # Wiki
      project.wiki.create_page('index_page', 'term')
      project.wiki.index_blobs
      project1.wiki.create_page('index_page', ' term')
      project1.wiki.index_blobs

      Gitlab::Elastic::Helper.refresh_index

      result = described_class.new(user, 'term', project.id)
      expect(result.notes_count).to eq(1)
      expect(result.wiki_blobs_count).to eq(1)
      expect(result.blobs_count).to eq(1)

      result1 = described_class.new(user, 'initial', project.id)
      expect(result1.commits_count).to eq(1)
    end

    context 'visibility checks' do
      it 'shows wiki for guests' do
        project = create :project, :public, :wiki_repo
        guest = create :user
        project.add_guest(guest)

        # Wiki
        project.wiki.create_page('index_page', 'term')
        project.wiki.index_blobs

        Gitlab::Elastic::Helper.refresh_index

        result = described_class.new(guest, 'term', project.id)
        expect(result.wiki_blobs_count).to eq(1)
      end
    end
  end

  describe "search for commits in non-default branch" do
    let(:project) { create(:project, :public, :repository, visibility) }
    let(:visibility) { :repository_enabled }
    let(:result) { described_class.new(user, 'initial', project.id, 'test') }

    subject(:commits) { result.objects('commits') }

    it 'finds needed commit' do
      expect(result.commits_count).to eq(1)
    end

    it 'responds to total_pages method' do
      expect(commits.total_pages).to eq(1)
    end

    context 'disabled repository' do
      let(:visibility) { :repository_disabled }

      it 'hides commits from members' do
        project.add_reporter(user)

        is_expected.to be_empty
      end

      it 'hides commits from non-members' do
        is_expected.to be_empty
      end
    end

    context 'private repository' do
      let(:visibility) { :repository_private }

      it 'shows commits to members' do
        project.add_reporter(user)

        is_expected.not_to be_empty
      end

      it 'hides commits from non-members' do
        is_expected.to be_empty
      end
    end
  end

  describe 'search for blobs in non-default branch' do
    let(:project) { create(:project, :public, :repository, :repository_private) }
    let(:result) { described_class.new(user, 'initial', project.id, 'test') }

    subject(:blobs) { result.objects('blobs') }

    it 'uses FileFinder instead of ES search' do
      project.add_reporter(user)

      expect_any_instance_of(Gitlab::FileFinder).to receive(:find).with('initial').and_return([])

      _ = blobs
    end

    it 'respects project visibility' do
      expect_any_instance_of(Gitlab::FileFinder).to receive(:find).never

      is_expected.to be_empty
    end
  end

  describe 'confidential issues' do
    let(:query) { 'issue' }
    let(:author) { create(:user) }
    let(:assignee) { create(:user) }
    let(:non_member) { create(:user) }
    let(:member) { create(:user) }
    let(:admin) { create(:admin) }
    let!(:issue) { create(:issue, project: project, title: 'Issue 1') }
    let!(:security_issue_1) { create(:issue, :confidential, project: project, title: 'Security issue 1', author: author) }
    let!(:security_issue_2) { create(:issue, :confidential, title: 'Security issue 2', project: project, assignees: [assignee]) }

    before do
      Gitlab::Elastic::Helper.refresh_index
    end

    it 'does not list project confidential issues for non project members' do
      results = described_class.new(non_member, query, project.id)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(results.issues_count).to eq 1
    end

    it 'lists project confidential issues for author' do
      results = described_class.new(author, query, project.id)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(results.issues_count).to eq 2
    end

    it 'lists project confidential issues for assignee' do
      results = described_class.new(assignee, query, project.id)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).to include security_issue_2
      expect(results.issues_count).to eq 2
    end

    it 'lists project confidential issues for project members' do
      project.add_developer(member)

      results = described_class.new(member, query, project.id)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).to include security_issue_2
      expect(results.issues_count).to eq 3
    end

    it 'does not list project confidential issues for project members with guest role' do
      project.add_guest(member)

      results = described_class.new(member, query, project.id)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(results.issues_count).to eq 1
    end

    it 'lists all project issues for admin' do
      results = described_class.new(admin, query, project.id)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).to include security_issue_2
      expect(results.issues_count).to eq 3
    end
  end
end
