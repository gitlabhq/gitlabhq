# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitsHelper do
  include ProjectForksHelper

  describe 'commit_author_link' do
    it 'escapes the author email' do
      commit = double(
        author: nil,
        author_name: 'Persistent XSS',
        author_email: 'my@email.com" onmouseover="alert(1)'
      )

      expect(helper.commit_author_link(commit))
        .not_to include('onmouseover="alert(1)"')
    end

    it 'escapes the author name' do
      user = build_stubbed(:user, name: 'Foo <script>alert("XSS")</script>')

      commit = double(author: user, author_name: '', author_email: '')

      expect(helper.commit_author_link(commit))
        .to include('Foo &lt;script&gt;')
      expect(helper.commit_author_link(commit, avatar: true))
        .to include('commit-author-name', 'js-user-link', 'Foo &lt;script&gt;')
    end
  end

  describe 'commit_committer_link' do
    it 'escapes the committer email' do
      commit = double(
        committer: nil,
        committer_name: 'Persistent XSS',
        committer_email: 'my@email.com" onmouseover="alert(1)'
      )

      expect(helper.commit_committer_link(commit))
        .not_to include('onmouseover="alert(1)"')
    end

    it 'escapes the committer name' do
      user = build_stubbed(:user, name: 'Foo <script>alert("XSS")</script>')

      commit = double(committer: user, committer_name: '', committer_email: '')

      expect(helper.commit_committer_link(commit))
        .to include('Foo &lt;script&gt;')
      expect(helper.commit_committer_link(commit, avatar: true))
        .to include('commit-committer-name', 'Foo &lt;script&gt;')
    end
  end

  describe '#view_file_button' do
    let(:project) { build(:project) }
    let(:path) { 'path/to/file' }
    let(:sha) { '1234567890' }

    subject do
      helper.view_file_button(sha, path, project)
    end

    it 'links to project files' do
      expect(subject).to have_link('1234567', href: helper.project_blob_path(project, "#{sha}/#{path}"))
    end
  end

  describe '#view_on_environment_button' do
    let(:project) { create(:project) }
    let(:environment) { create(:environment, external_url: 'http://example.com') }
    let(:path) { 'source/file.html' }
    let(:sha) { RepoHelpers.sample_commit.id }

    before do
      allow(environment).to receive(:external_url_for).with(path, sha).and_return('http://example.com/file.html')
    end

    it 'returns a link tag linking to the file in the environment' do
      html = helper.view_on_environment_button(sha, path, environment)
      node = Nokogiri::HTML.parse(html).at_css('a')

      expect(node[:title]).to eq('View on example.com')
      expect(node[:href]).to eq('http://example.com/file.html')
    end
  end

  describe '#diff_mode_swap_button' do
    let(:keyword) { 'rendered' }
    let(:node) { Nokogiri::HTML.parse(helper.diff_mode_swap_button(keyword, 'abc')).at_css('a') }

    context 'for rendered' do
      it 'renders the correct select-rendered button', :aggregate_failures do
        expect(node[:title]).to eq('Display rendered diff')
        expect(node['data-file-hash']).to eq('abc')
        expect(node['data-diff-toggle-entity']).to eq('renderedButton')
        expect(node.xpath("//a/span/svg")[0]["data-testid"]).to eq('doc-text-icon')
      end
    end

    context 'for raw' do
      let(:keyword) { 'raw' }

      it 'renders the correct select-raw button', :aggregate_failures do
        expect(node[:title]).to eq('Display raw diff')
        expect(node['data-file-hash']).to eq('abc')
        expect(node['data-diff-toggle-entity']).to eq('rawButton')
        expect(node.xpath("//a/span/svg")[0]["data-testid"]).to eq('doc-code-icon')
      end
    end
  end

  describe '#commit_to_html' do
    let(:project) { create(:project, :repository) }
    let(:ref) { 'master' }
    let(:commit) { project.commit(ref) }

    it 'renders HTML representation of a commit' do
      assign(:project, project)
      allow(helper).to receive(:current_user).and_return(project.owner)

      expect(helper.commit_to_html(commit, ref, project)).to include('<div class="commit-content')
    end
  end

  describe 'commit_path' do
    it 'returns a persisted merge request commit path' do
      project = create(:project, :repository)
      persisted_merge_request = create(:merge_request, source_project: project, target_project: project)
      commit = project.repository.commit

      expect(helper.commit_path(persisted_merge_request.project, commit, merge_request: persisted_merge_request))
        .to eq(diffs_project_merge_request_path(project, persisted_merge_request, commit_id: commit.id))
    end

    it 'returns a non-persisted merge request commit path which commits still reside in the source project' do
      source_project = create(:project, :repository)
      target_project = create(:project, :repository)
      non_persisted_merge_request = build(:merge_request, source_project: source_project, target_project: target_project)
      commit = source_project.repository.commit

      expect(helper.commit_path(non_persisted_merge_request.project, commit, merge_request: non_persisted_merge_request))
        .to eq(project_commit_path(source_project, commit))
    end

    it 'returns a project commit path' do
      project = create(:project, :repository)
      commit = project.repository.commit

      expect(helper.commit_path(project, commit)).to eq(project_commit_path(project, commit))
    end
  end

  describe "#conditionally_paginate_diff_files" do
    let_it_be(:project) { create(:project, :repository) }

    let(:diffs_collection) { instance_double(Gitlab::Diff::FileCollection::Commit, diff_files: decorated_diff_files, project: project) }
    let(:decorated_diff_files) do
      diffs.map do |diff|
        Gitlab::Diff::File.new(diff, repository: project.repository)
      end
    end

    let(:diffs) { Gitlab::Git::DiffCollection.new(files) }
    let(:files) do
      Array.new(85).map do
        { too_large: false, diff: "" }
      end
    end

    let(:page) { nil }

    subject { helper.conditionally_paginate_diff_files(diffs_collection, paginate: paginate, page: page, per: Projects::CommitController::COMMIT_DIFFS_PER_PAGE) }

    before do
      allow(helper).to receive(:params).and_return(params)
    end

    context "pagination is enabled" do
      let(:paginate) { true }

      it "has been paginated" do
        expect(subject).to be_an(Array)
      end

      it "can change the number of items per page" do
        commits = helper.conditionally_paginate_diff_files(diffs_collection, page: page, paginate: paginate, per: 10)

        expect(commits).to be_an(Array)
        expect(commits.size).to eq(10)
      end

      context "page 1" do
        let(:page) { 1 }

        it "has 20 diffs" do
          expect(subject.size).to eq(20)
        end
      end

      context "page 5" do
        let(:page) { 5 }

        it "has the remaining 5 out of 85 diffs" do
          expect(subject.size).to eq(5)
        end
      end
    end

    context "pagination is disabled" do
      let(:paginate) { false }

      it "returns the unpaginated collection" do
        expect(subject.size).to eq(85)
      end
    end
  end

  describe '#cherry_pick_projects_data' do
    let(:project) { create(:project, :repository) }
    let(:user) { create(:user, maintainer_of: project) }
    let!(:forked_project) { fork_project(project, user, { namespace: user.namespace, repository: true }) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'returns data for cherry picking into a project' do
      expect(helper.cherry_pick_projects_data(forked_project)).to match_array(
        [
          { id: project.id.to_s, name: project.full_path, refsUrl: refs_project_path(project) },
          { id: forked_project.id.to_s, name: forked_project.full_path, refsUrl: refs_project_path(forked_project) }
        ])
    end
  end

  describe "#commit_options_dropdown_data" do
    let(:project) { build(:project, :repository) }
    let(:commit) { build(:commit) }
    let(:user) { build(:user) }

    subject { helper.commit_options_dropdown_data(project, commit) }

    context "when user is logged in" do
      before do
        allow(helper).to receive(:can?).with(user, :push_code, project).and_return(true)
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "returns data as expected" do
        is_expected.to eq standard_expected_data
      end

      context "when can not collaborate on project" do
        before do
          allow(helper).to receive(:can_collaborate_with_project?).with(project).and_return(false)
        end

        it "returns data as expected" do
          no_collaboration_values = {
            can_revert: 'false',
            can_cherry_pick: 'false'
          }

          is_expected.to eq standard_expected_data.merge(no_collaboration_values)
        end
      end

      context "when commit has already been reverted" do
        before do
          allow(commit).to receive(:has_been_reverted?).with(user).and_return(true)
        end

        it "returns data as expected" do
          is_expected.to eq standard_expected_data.merge({ can_revert: 'false' })
        end
      end
    end

    context "when user is not logged in" do
      before do
        allow(helper).to receive(:can?).with(nil, :push_code, project).and_return(false)
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it "returns data as expected" do
        logged_out_values = {
          can_revert: '',
          can_cherry_pick: '',
          can_tag: 'false'
        }

        is_expected.to eq standard_expected_data.merge(logged_out_values)
      end
    end

    def standard_expected_data
      {
        new_project_tag_path: new_project_tag_path(project, ref: commit),
        email_patches_path: project_commit_path(project, commit, format: :patch),
        plain_diff_path: project_commit_path(project, commit, format: :diff),
        can_revert: 'true',
        can_cherry_pick: 'true',
        can_tag: 'true',
        can_email_patches: 'true'
      }
    end
  end

  describe "#commit_partial_cache_key" do
    subject(:cache_key) { helper.commit_partial_cache_key(commit, ref: ref, merge_request: merge_request, request: request) }

    let(:commit) { create(:commit).present(current_user: user) }
    let(:commit_status) { Gitlab::Ci::Status::Running.new(pipeline, user) }
    let(:pipeline) { create(:ci_pipeline, :running) }
    let(:user) { create(:user) }
    let(:ref) { "master" }
    let(:merge_request) { create(:merge_request) }
    let(:request) { double(xhr?: true) }
    let(:current_path) { "test" }

    before do
      expect(commit).to receive(:detailed_status_for).with(ref).and_return(commit_status)
      assign(:path, current_path)
    end

    specify do
      expect(subject).to eq([
        commit,
        commit.author,
        ref,
        {
          merge_request: merge_request.cache_key,
          pipeline_status: pipeline.cache_key,
          xhr: true,
          controller: "commits",
          path: current_path,
          referenced_by: helper.tag_checksum(commit.referenced_by)
        }
      ])
    end

    describe "final cache key output" do
      subject { ActiveSupport::Cache.expand_cache_key(cache_key) }

      it { is_expected.to include(commit.cache_key) }
      it { is_expected.to include(pipeline.cache_key) }
    end
  end

  describe "#commit_path_template" do
    let(:project) { build(:project) }
    let(:expected_path) { "/#{project.full_path}/-/commit/$COMMIT_SHA" }

    subject { helper.commit_path_template(project) }

    it { is_expected.to eq(expected_path) }
  end

  describe '#local_committed_date' do
    let(:commit) { build(:commit, committed_date: time) }
    let(:user) { build(:user) }
    let(:time) { Time.find_zone('UTC').parse('2023-01-01') }

    subject { helper.local_committed_date(commit, user).to_s }

    it { is_expected.to eq('2023-01-01') }

    context 'when user has a custom timezone' do
      let(:user) { build(:user, timezone: 'America/Mexico_City') }

      it 'selects timezone of the user' do
        is_expected.to eq('2022-12-31')
      end
    end

    context "when user doesn't have a preferred timezone" do
      let(:user) { build(:user, timezone: nil) }

      it 'uses system timezone' do
        is_expected.to eq('2023-01-01')
      end
    end

    context 'when user timezone is not supported' do
      let(:user) { build(:user, timezone: 'unknown') }

      it 'uses system timezone' do
        is_expected.to eq('2023-01-01')
      end
    end

    context 'when user is missing' do
      let(:user) { nil }

      it 'uses system timezone' do
        is_expected.to eq('2023-01-01')
      end
    end
  end
end
