# coding: utf-8
require 'spec_helper'

describe Gitlab::Elastic::SearchResults do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    Gitlab::Elastic::Helper.create_empty_index
  end

  after do
    Gitlab::Elastic::Helper.delete_index
    stub_ee_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  let(:user) { create(:user) }
  let(:project_1) { create(:project, :repository) }
  let(:project_2) { create(:project, :repository) }
  let(:limit_project_ids) { [project_1.id] }

  describe 'parse_search_result' do
    let(:blob) do
      {
        'blob' => {
          'commit_sha' => 'sha',
          'content' => "foo\nbar\nbaz\n",
          'path' => 'path/file.ext'
        }
      }
    end

    it 'returns an unhighlighted blob when no highlight data is present' do
      parsed = described_class.parse_search_result('_source' => blob)

      expect(parsed).to be_kind_of(::Gitlab::SearchResults::FoundBlob)
      expect(parsed).to have_attributes(
        startline: 1,
        data: "foo\n"
      )
    end

    it 'parses the blob with highlighting' do
      result = {
        '_source' => blob,
        'highlight' => {
          'blob.content' => ["foo\ngitlabelasticsearch→bar←gitlabelasticsearch\nbaz\n"]
        }
      }

      parsed = described_class.parse_search_result(result)

      expect(parsed).to be_kind_of(::Gitlab::SearchResults::FoundBlob)
      expect(parsed).to have_attributes(
        id: nil,
        filename: 'path/file.ext',
        basename: 'path/file',
        ref: 'sha',
        startline: 2,
        data: "bar\n"
      )
    end
  end

  describe 'issues' do
    before do
      @issue_1 = create(
        :issue,
        project: project_1,
        title: 'Hello world, here I am!',
        iid: 1
      )
      @issue_2 = create(
        :issue,
        project: project_1,
        title: 'Issue 2',
        description: 'Hello world, here I am!',
        iid: 2
      )
      @issue_3 = create(
        :issue,
        project: project_2,
        title: 'Issue 3',
        iid: 2
      )

      Gitlab::Elastic::Helper.refresh_index
    end

    it 'lists found issues' do
      results = described_class.new(user, 'hello world', limit_project_ids)
      issues = results.objects('issues')

      expect(issues).to include @issue_1
      expect(issues).to include @issue_2
      expect(issues).not_to include @issue_3
      expect(results.issues_count).to eq 2
    end

    it 'returns empty list when issues are not found' do
      results = described_class.new(user, 'security', limit_project_ids)

      expect(results.objects('issues')).to be_empty
      expect(results.issues_count).to eq 0
    end

    it 'lists issue when search by a valid iid' do
      results = described_class.new(user, '#2', limit_project_ids)
      issues = results.objects('issues')

      expect(issues).not_to include @issue_1
      expect(issues).to include @issue_2
      expect(issues).not_to include @issue_3
      expect(results.issues_count).to eq 1
    end

    it 'returns empty list when search by invalid iid' do
      results = described_class.new(user, '#222', limit_project_ids)

      expect(results.objects('issues')).to be_empty
      expect(results.issues_count).to eq 0
    end
  end

  describe 'confidential issues' do
    let(:project_3) { create(:project) }
    let(:project_4) { create(:project) }
    let(:limit_project_ids) { [project_1.id, project_2.id, project_3.id] }
    let(:author) { create(:user) }
    let(:assignee) { create(:user) }
    let(:non_member) { create(:user) }
    let(:member) { create(:user) }
    let(:admin) { create(:admin) }

    before do
      @issue = create(:issue, project: project_1, title: 'Issue 1', iid: 1)
      @security_issue_1 = create(:issue, :confidential, project: project_1, title: 'Security issue 1', author: author, iid: 2)
      @security_issue_2 = create(:issue, :confidential, title: 'Security issue 2', project: project_1, assignees: [assignee], iid: 3)
      @security_issue_3 = create(:issue, :confidential, project: project_2, title: 'Security issue 3', author: author, iid: 1)
      @security_issue_4 = create(:issue, :confidential, project: project_3, title: 'Security issue 4', assignees: [assignee], iid: 1)
      @security_issue_5 = create(:issue, :confidential, project: project_4, title: 'Security issue 5', iid: 1)

      Gitlab::Elastic::Helper.refresh_index
    end

    context 'search by term' do
      let(:query) { 'issue' }

      it 'does not list confidential issues for guests' do
        results = described_class.new(nil, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 1
      end

      it 'does not list confidential issues for non project members' do
        results = described_class.new(non_member, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 1
      end

      it 'lists confidential issues for author' do
        results = described_class.new(author, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 3
      end

      it 'lists confidential issues for assignee' do
        results = described_class.new(assignee, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 3
      end

      it 'lists confidential issues for project members' do
        project_1.add_developer(member)
        project_2.add_developer(member)

        results = described_class.new(member, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).to include @security_issue_1
        expect(issues).to include @security_issue_2
        expect(issues).to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 4
      end

      it 'lists all issues for admin' do
        results = described_class.new(admin, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).to include @security_issue_1
        expect(issues).to include @security_issue_2
        expect(issues).to include @security_issue_3
        expect(issues).to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 5
      end
    end

    context 'search by iid' do
      let(:query) { '#1' }

      it 'does not list confidential issues for guests' do
        results = described_class.new(nil, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 1
      end

      it 'does not list confidential issues for non project members' do
        results = described_class.new(non_member, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 1
      end

      it 'lists confidential issues for author' do
        results = described_class.new(author, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 2
      end

      it 'lists confidential issues for assignee' do
        results = described_class.new(assignee, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 2
      end

      it 'lists confidential issues for project members' do
        project_2.add_developer(member)
        project_3.add_developer(member)

        results = described_class.new(member, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).to include @security_issue_3
        expect(issues).to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 3
      end

      it 'lists all issues for admin' do
        results = described_class.new(admin, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).to include @security_issue_3
        expect(issues).to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 3
      end
    end
  end

  describe 'merge requests' do
    before do
      @merge_request_1 = create(
        :merge_request,
        source_project: project_1,
        target_project: project_1,
        title: 'Hello world, here I am!',
        iid: 1
      )
      @merge_request_2 = create(
        :merge_request,
        :conflict,
        source_project: project_1,
        target_project: project_1,
        title: 'Merge Request 2',
        description: 'Hello world, here I am!',
        iid: 2
      )
      @merge_request_3 = create(
        :merge_request,
        source_project: project_2,
        target_project: project_2,
        title: 'Merge Request 3',
        iid: 2
      )

      Gitlab::Elastic::Helper.refresh_index
    end

    it 'lists found merge requests' do
      results = described_class.new(user, 'hello world', limit_project_ids)
      merge_requests = results.objects('merge_requests')

      expect(merge_requests).to include @merge_request_1
      expect(merge_requests).to include @merge_request_2
      expect(merge_requests).not_to include @merge_request_3
      expect(results.merge_requests_count).to eq 2
    end

    it 'returns empty list when merge requests are not found' do
      results = described_class.new(user, 'security', limit_project_ids)

      expect(results.objects('merge_requests')).to be_empty
      expect(results.merge_requests_count).to eq 0
    end

    it 'lists merge request when search by a valid iid' do
      results = described_class.new(user, '#2', limit_project_ids)
      merge_requests = results.objects('merge_requests')

      expect(merge_requests).not_to include @merge_request_1
      expect(merge_requests).to include @merge_request_2
      expect(merge_requests).not_to include @merge_request_3
      expect(results.merge_requests_count).to eq 1
    end

    it 'returns empty list when search by invalid iid' do
      results = described_class.new(user, '#222', limit_project_ids)

      expect(results.objects('merge_requests')).to be_empty
      expect(results.merge_requests_count).to eq 0
    end
  end

  describe 'project scoping' do
    it "returns items for project" do
      project = create :project, :repository, name: "term"

      # Create issue
      create :issue, title: 'bla-bla term', project: project
      create :issue, description: 'bla-bla term', project: project
      create :issue, project: project
      # The issue I have no access to
      create :issue, title: 'bla-bla term'

      # Create Merge Request
      create :merge_request, title: 'bla-bla term', source_project: project
      create :merge_request, description: 'term in description', source_project: project, target_branch: "feature2"
      create :merge_request, source_project: project, target_branch: "feature3"
      # The merge request you have no access to
      create :merge_request, title: 'also with term'

      create :milestone, title: 'bla-bla term', project: project
      create :milestone, description: 'bla-bla term', project: project
      create :milestone, project: project
      # The Milestone you have no access to
      create :milestone, title: 'bla-bla term'

      Gitlab::Elastic::Helper.refresh_index

      result = described_class.new(user, 'term', [project.id])

      expect(result.issues_count).to eq(2)
      expect(result.merge_requests_count).to eq(2)
      expect(result.milestones_count).to eq(2)
      expect(result.projects_count).to eq(1)
    end
  end

  describe 'Blobs' do
    before do
      project_1.repository.index_blobs

      Gitlab::Elastic::Helper.refresh_index
    end

    def search_for(term)
      blobs = described_class.new(user, term, [project_1.id]).objects('blobs')

      blobs.map do |blob|
        blob['_source']['blob']['path']
      end
    end

    it 'finds blobs' do
      results = described_class.new(user, 'def', limit_project_ids)
      blobs = results.objects('blobs')

      expect(blobs.first['_source']['blob']['content']).to include('def')
      expect(results.blobs_count).to eq 7
    end

    it 'finds blobs from public projects only' do
      project_2 = create :project, :repository, :private
      project_2.repository.index_blobs
      Gitlab::Elastic::Helper.refresh_index

      results = described_class.new(user, 'def', [project_1.id])
      expect(results.blobs_count).to eq 7

      results = described_class.new(user, 'def', [project_1.id, project_2.id])

      expect(results.blobs_count).to eq 14
    end

    it 'returns zero when blobs are not found' do
      results = described_class.new(user, 'asdfg', limit_project_ids)

      expect(results.blobs_count).to eq 0
    end

    context 'Searches CamelCased methods' do
      before do
        project_1.repository.create_file(
          user,
          'test.txt',
          ' function writeStringToFile(){} ',
          message: 'added test file',
          branch_name: 'master')

        project_1.repository.index_blobs

        Gitlab::Elastic::Helper.refresh_index
      end

      it 'find by first word' do
        expect(search_for('write')).to include('test.txt')
      end

      it 'find by first two words' do
        expect(search_for('writeString')).to include('test.txt')
      end

      it 'find by last two words' do
        expect(search_for('ToFile')).to include('test.txt')
      end

      it 'find by exact match' do
        expect(search_for('writeStringToFile')).to include('test.txt')
      end
    end

    context 'Searches special characters' do
      let(:file_content) do
        <<~FILE
          us

          some other stuff

          dots.also.need.testing

          and;colons:too$
          wow
          yeah!

          Foo.bar(x)

          include "bikes-3.4"

          us-east-2
          bye
        FILE
      end
      let(:file_name) { 'elastic_specialchars_test.md' }

      before do
        project_1.repository.create_file(user, file_name, file_content, message: 'Some commit message', branch_name: 'master')
        project_1.repository.index_blobs
        Gitlab::Elastic::Helper.refresh_index
      end

      it 'finds files with dashes' do
        expect(search_for('"us-east-2"')).to include(file_name)
        expect(search_for('bikes-3.4')).to include(file_name)
      end

      it 'finds files with dots' do
        expect(search_for('"dots.also.need.testing"')).to include(file_name)
        expect(search_for('dots')).to include(file_name)
        expect(search_for('need')).to include(file_name)
        expect(search_for('dots.need')).not_to include(file_name)
      end

      it 'finds files with other special chars' do
        expect(search_for('"and;colons:too$"')).to include(file_name)
        expect(search_for('bar\(x\)')).to include(file_name)
      end
    end
  end

  describe 'Wikis' do
    let(:results) { described_class.new(user, 'term', limit_project_ids) }
    subject(:wiki_blobs) { results.objects('wiki_blobs') }

    before do
      project_1.wiki.create_page('index_page', 'term')
      project_1.wiki.index_blobs

      Gitlab::Elastic::Helper.refresh_index
    end

    it 'finds wiki blobs' do
      blobs = results.objects('wiki_blobs')

      expect(blobs.first['_source']['blob']['content']).to include("term")
      expect(results.wiki_blobs_count).to eq 1
    end

    it 'finds wiki blobs for guest' do
      project_1.add_guest(user)
      blobs = results.objects('wiki_blobs')

      expect(blobs.first['_source']['blob']['content']).to include("term")
      expect(results.wiki_blobs_count).to eq 1
    end

    it 'finds wiki blobs from public projects only' do
      project_2 = create :project, :repository, :private
      project_2.wiki.create_page('index_page', 'term')
      project_2.wiki.index_blobs
      Gitlab::Elastic::Helper.refresh_index

      expect(results.wiki_blobs_count).to eq 1

      results = described_class.new(user, 'term', [project_1.id, project_2.id])
      expect(results.wiki_blobs_count).to eq 2
    end

    it 'returns zero when wiki blobs are not found' do
      results = described_class.new(user, 'asdfg', limit_project_ids)

      expect(results.wiki_blobs_count).to eq 0
    end

    context 'when wiki is disabled' do
      let(:project_1) { create(:project, :public, :repository, :wiki_disabled) }

      context 'search by member' do
        let(:limit_project_ids) { [project_1.id] }

        it { is_expected.to be_empty }
      end

      context 'search by non-member' do
        let(:limit_project_ids) { [] }

        it { is_expected.to be_empty }
      end
    end

    context 'when wiki is internal' do
      let(:project_1) { create(:project, :public, :repository, :wiki_private) }

      context 'search by member' do
        let(:limit_project_ids) { [project_1.id] }

        it { is_expected.not_to be_empty }
      end

      context 'search by non-member' do
        let(:limit_project_ids) { [] }

        it { is_expected.to be_empty }
      end
    end
  end

  describe 'Commits' do
    before do
      project_1.repository.index_commits

      Gitlab::Elastic::Helper.refresh_index
    end

    it 'finds commits' do
      results = described_class.new(user, 'add', limit_project_ids)
      commits = results.objects('commits')

      expect(commits.first.message).to include("Add")
      expect(results.commits_count).to eq 24
    end

    it 'finds commits from public projects only' do
      project_2 = create :project, :private, :repository
      project_2.repository.index_commits
      Gitlab::Elastic::Helper.refresh_index

      results = described_class.new(user, 'add', [project_1.id])
      expect(results.commits_count).to eq 24

      results = described_class.new(user, 'add', [project_1.id, project_2.id])
      expect(results.commits_count).to eq 48
    end

    it 'returns zero when commits are not found' do
      results = described_class.new(user, 'asdfg', limit_project_ids)

      expect(results.commits_count).to eq 0
    end
  end

  describe 'Visibility levels' do
    let(:internal_project) { create(:project, :internal, :repository, description: "Internal project") }
    let(:private_project1) { create(:project, :private, :repository, description: "Private project") }
    let(:private_project2) { create(:project, :private, :repository, description: "Private project where I'm a member") }
    let(:public_project) { create(:project, :public, :repository, description: "Public project") }
    let(:limit_project_ids) { [private_project2.id] }

    before do
      private_project2.project_members.create(user: user, access_level: ProjectMember::DEVELOPER)
    end

    context 'Issues' do
      it 'finds right set of issues' do
        issue_1 = create :issue, project: internal_project, title: "Internal project"
        create :issue, project: private_project1, title: "Private project"
        issue_3 = create :issue, project: private_project2, title: "Private project where I'm a member"
        issue_4 = create :issue, project: public_project, title: "Public project"

        Gitlab::Elastic::Helper.refresh_index

        # Authenticated search
        results = described_class.new(user, 'project', limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include issue_1
        expect(issues).to include issue_3
        expect(issues).to include issue_4
        expect(results.issues_count).to eq 3

        # Unauthenticated search
        results = described_class.new(nil, 'project', [])
        issues = results.objects('issues')

        expect(issues).to include issue_4
        expect(results.issues_count).to eq 1
      end
    end

    context 'Milestones' do
      it 'finds right set of milestine' do
        milestone_1 = create :milestone, project: internal_project, title: "Internal project"
        create :milestone, project: private_project1, title: "Private project"
        milestone_3 = create :milestone, project: private_project2, title: "Private project where I'm a member"
        milestone_4 = create :milestone, project: public_project, title: "Public project"

        Gitlab::Elastic::Helper.refresh_index

        # Authenticated search
        results = described_class.new(user, 'project', limit_project_ids)
        milestones = results.objects('milestones')

        expect(milestones).to include milestone_1
        expect(milestones).to include milestone_3
        expect(milestones).to include milestone_4
        expect(results.milestones_count).to eq 3

        # Unauthenticated search
        results = described_class.new(nil, 'project', [])
        milestones = results.objects('milestones')

        expect(milestones).to include milestone_4
        expect(results.milestones_count).to eq 1
      end
    end

    context 'Projects' do
      it 'finds right set of projects' do
        internal_project
        private_project1
        private_project2
        public_project

        Gitlab::Elastic::Helper.refresh_index

        # Authenticated search
        results = described_class.new(user, 'project', limit_project_ids)
        milestones = results.objects('projects')

        expect(milestones).to include internal_project
        expect(milestones).to include private_project2
        expect(milestones).to include public_project
        expect(results.projects_count).to eq 3

        # Unauthenticated search
        results = described_class.new(nil, 'project', [])
        projects = results.objects('projects')

        expect(projects).to include public_project
        expect(results.projects_count).to eq 1
      end
    end

    context 'Merge Requests' do
      it 'finds right set of merge requests' do
        merge_request_1 = create :merge_request, target_project: internal_project, source_project: internal_project, title: "Internal project"
        create :merge_request, target_project: private_project1, source_project: private_project1, title: "Private project"
        merge_request_3 = create :merge_request, target_project: private_project2, source_project: private_project2, title: "Private project where I'm a member"
        merge_request_4 = create :merge_request, target_project: public_project, source_project: public_project, title: "Public project"

        Gitlab::Elastic::Helper.refresh_index

        # Authenticated search
        results = described_class.new(user, 'project', limit_project_ids)
        merge_requests = results.objects('merge_requests')

        expect(merge_requests).to include merge_request_1
        expect(merge_requests).to include merge_request_3
        expect(merge_requests).to include merge_request_4
        expect(results.merge_requests_count).to eq 3

        # Unauthenticated search
        results = described_class.new(nil, 'project', [])
        merge_requests = results.objects('merge_requests')

        expect(merge_requests).to include merge_request_4
        expect(results.merge_requests_count).to eq 1
      end
    end

    context 'Wikis' do
      before do
        [public_project, internal_project, private_project1, private_project2].each do |project|
          project.wiki.create_page('index_page', 'term')
          project.wiki.index_blobs
        end

        Gitlab::Elastic::Helper.refresh_index
      end

      it 'finds the right set of wiki blobs' do
        # Authenticated search
        results = described_class.new(user, 'term', limit_project_ids)
        blobs = results.objects('wiki_blobs')

        expect(blobs.map {|blob| blob._parent.to_i }).to match_array [internal_project.id, private_project2.id, public_project.id]
        expect(results.wiki_blobs_count).to eq 3

        # Unauthenticated search
        results = described_class.new(nil, 'term', [])
        blobs = results.objects('wiki_blobs')

        expect(blobs.first._parent.to_i).to eq public_project.id
        expect(results.wiki_blobs_count).to eq 1
      end
    end

    context 'Commits' do
      it 'finds right set of commits' do
        [internal_project, private_project1, private_project2, public_project].each do |project|
          project.repository.create_file(
            user,
            'test-file',
            'search test',
            message: 'search test',
            branch_name: 'master'
          )

          project.repository.index_commits
        end

        Gitlab::Elastic::Helper.refresh_index

        # Authenticated search
        results = described_class.new(user, 'search', limit_project_ids)
        commits = results.objects('commits')

        expect(commits.map(&:project)).to match_array [internal_project, private_project2, public_project]
        expect(results.commits_count).to eq 3

        # Unauthenticated search
        results = described_class.new(nil, 'search', [])
        commits = results.objects('commits')

        expect(commits.first.project).to eq public_project
        expect(results.commits_count).to eq 1
      end
    end

    context 'Blobs' do
      it 'finds right set of blobs' do
        [internal_project, private_project1, private_project2, public_project].each do |project|
          project.repository.create_file(
            user,
            'test-file',
            'tesla',
            message: 'search test',
            branch_name: 'master'
          )

          project.repository.index_blobs
        end

        Gitlab::Elastic::Helper.refresh_index

        # Authenticated search
        results = described_class.new(user, 'tesla', limit_project_ids)
        blobs = results.objects('blobs')

        expect(blobs.map { |blob| blob._parent.to_i }).to match_array [internal_project.id, private_project2.id, public_project.id]
        expect(results.blobs_count).to eq 3

        # Unauthenticated search
        results = described_class.new(nil, 'tesla', [])
        blobs = results.objects('blobs')

        expect(blobs.first._parent.to_i).to eq public_project.id.to_i
        expect(results.blobs_count).to eq 1
      end
    end
  end
end
