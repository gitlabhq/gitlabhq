# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabRoutingHelper do
  let(:project) { build_stubbed(:project) }
  let(:group) { build_stubbed(:group) }

  describe 'Project URL helpers' do
    describe '#project_member_path' do
      let(:project_member) { create(:project_member) }

      it { expect(project_member_path(project_member)).to eq project_project_member_path(project_member.source, project_member) }
    end

    describe '#request_access_project_members_path' do
      it { expect(request_access_project_members_path(project)).to eq request_access_project_project_members_path(project) }
    end

    describe '#leave_project_members_path' do
      it { expect(leave_project_members_path(project)).to eq leave_project_project_members_path(project) }
    end

    describe '#approve_access_request_project_member_path' do
      let(:project_member) { create(:project_member) }

      it { expect(approve_access_request_project_member_path(project_member)).to eq approve_access_request_project_project_member_path(project_member.source, project_member) }
    end

    describe '#resend_invite_project_member_path' do
      let(:project_member) { create(:project_member) }

      it { expect(resend_invite_project_member_path(project_member)).to eq resend_invite_project_project_member_path(project_member.source, project_member) }
    end
  end

  describe 'Group URL helpers' do
    describe '#group_members_url' do
      it { expect(group_members_url(group)).to eq group_group_members_url(group) }
    end

    describe '#group_member_path' do
      let(:group_member) { create(:group_member) }

      it { expect(group_member_path(group_member)).to eq group_group_member_path(group_member.source, group_member) }
    end

    describe '#request_access_group_members_path' do
      it { expect(request_access_group_members_path(group)).to eq request_access_group_group_members_path(group) }
    end

    describe '#leave_group_members_path' do
      it { expect(leave_group_members_path(group)).to eq leave_group_group_members_path(group) }
    end

    describe '#approve_access_request_group_member_path' do
      let(:group_member) { create(:group_member) }

      it { expect(approve_access_request_group_member_path(group_member)).to eq approve_access_request_group_group_member_path(group_member.source, group_member) }
    end

    describe '#resend_invite_group_member_path' do
      let(:group_member) { create(:group_member) }

      it { expect(resend_invite_group_member_path(group_member)).to eq resend_invite_group_group_member_path(group_member.source, group_member) }
    end
  end

  describe '#preview_markdown_path' do
    let(:project) { create(:project) }

    it 'returns group preview markdown path for a group parent' do
      group = create(:group)

      expect(preview_markdown_path(group)).to eq("/groups/#{group.path}/preview_markdown")
    end

    it 'returns group preview markdown path for a group parent with args' do
      group = create(:group)

      expect(preview_markdown_path(group, { type_id: 5 })).to eq("/groups/#{group.path}/preview_markdown?type_id=5")
    end

    it 'returns project preview markdown path for a project parent' do
      expect(preview_markdown_path(project)).to eq("/#{project.full_path}/preview_markdown")
    end

    it 'returns snippet preview markdown path for a personal snippet' do
      @snippet = create(:personal_snippet)

      expect(preview_markdown_path(nil)).to eq("/-/snippets/preview_markdown")
    end

    it 'returns project preview markdown path for a project snippet' do
      @snippet = create(:project_snippet, project: project)

      expect(preview_markdown_path(project)).to eq("/#{project.full_path}/preview_markdown")
    end
  end

  describe '#edit_milestone_path' do
    it 'returns group milestone edit path when given entity parent is a Group' do
      group = create(:group)
      milestone = create(:milestone, group: group)

      expect(edit_milestone_path(milestone)).to eq("/groups/#{group.path}/-/milestones/#{milestone.iid}/edit")
    end

    it 'returns project milestone edit path when given entity parent is not a Group' do
      milestone = create(:milestone, group: nil)

      expect(edit_milestone_path(milestone)).to eq("/#{milestone.project.full_path}/-/milestones/#{milestone.iid}/edit")
    end
  end

  describe 'members helpers' do
    describe '#source_members_url' do
      it 'returns a url to the memberships page for a group membership' do
        membership = build_stubbed(:group_member)
        group_members_url = "http://test.host/groups/#{membership.source.full_path}/-/group_members"

        expect(source_members_url(membership)).to eq(group_members_url)
      end

      it 'returns a url to the memberships page for a project membership' do
        membership = build_stubbed(:project_member)
        project_members_url = "http://test.host/#{membership.source.full_path}/-/project_members"

        expect(source_members_url(membership)).to eq(project_members_url)
      end
    end
  end

  context 'artifacts' do
    let_it_be(:project) { create(:project) }
    let_it_be(:job) { create(:ci_build, project: project, name: 'test:job', artifacts_expire_at: 1.hour.from_now) }

    describe '#fast_download_project_job_artifacts_path' do
      it 'matches the Rails download path' do
        expect(fast_download_project_job_artifacts_path(project, job)).to eq(download_project_job_artifacts_path(project, job))
      end

      context 'when given parameters' do
        it 'adds them to the path' do
          expect(
            fast_download_project_job_artifacts_path(project, job, file_type: :dast)
          ).to eq(
            download_project_job_artifacts_path(project, job, file_type: :dast)
          )
        end
      end
    end

    describe '#fast_keep_project_job_artifacts_path' do
      it 'matches the Rails keep path' do
        expect(fast_keep_project_job_artifacts_path(project, job)).to eq(keep_project_job_artifacts_path(project, job))
      end
    end

    describe '#fast_browse_project_job_artifacts_path' do
      it 'matches the Rails browse path' do
        expect(fast_browse_project_job_artifacts_path(project, job)).to eq(browse_project_job_artifacts_path(project, job))
      end
    end
  end

  context 'snippets' do
    let_it_be(:personal_snippet) { create(:personal_snippet, :repository) }
    let_it_be(:project_snippet) { create(:project_snippet, :repository) }
    let_it_be(:note) { create(:note_on_personal_snippet, noteable: personal_snippet) }

    describe '#gitlab_snippet_path' do
      it 'returns the personal snippet path' do
        expect(gitlab_snippet_path(personal_snippet)).to eq("/-/snippets/#{personal_snippet.id}")
      end

      it 'returns the project snippet path' do
        expect(gitlab_snippet_path(project_snippet)).to eq("/#{project_snippet.project.full_path}/-/snippets/#{project_snippet.id}")
      end
    end

    describe '#gitlab_snippet_url' do
      it 'returns the personal snippet url' do
        expect(gitlab_snippet_url(personal_snippet)).to eq("http://test.host/-/snippets/#{personal_snippet.id}")
      end

      it 'returns the project snippet url' do
        expect(gitlab_snippet_url(project_snippet)).to eq("http://test.host/#{project_snippet.project.full_path}/-/snippets/#{project_snippet.id}")
      end
    end

    describe '#gitlab_raw_snippet_path' do
      it 'returns the raw personal snippet path' do
        expect(gitlab_raw_snippet_path(personal_snippet)).to eq("/-/snippets/#{personal_snippet.id}/raw")
      end

      it 'returns the raw project snippet path' do
        expect(gitlab_raw_snippet_path(project_snippet)).to eq("/#{project_snippet.project.full_path}/-/snippets/#{project_snippet.id}/raw")
      end
    end

    describe '#gitlab_raw_snippet_blob_path' do
      let(:snippet) { personal_snippet }
      let(:blob) { snippet.blobs.first }
      let(:ref) { 'test-ref' }
      let(:args) { {} }

      subject { gitlab_raw_snippet_blob_path(snippet, blob.path, ref, **args) }

      it_behaves_like 'snippet blob raw path'

      context 'when an argument is set' do
        let(:args) { { inline: true } }

        it { expect(subject).to eq("/-/snippets/#{personal_snippet.id}/raw/#{ref}/#{blob.path}?inline=true") }
      end

      context 'without a ref' do
        let(:ref) { nil }
        let(:expected_ref) { blob.repository.root_ref }

        it 'uses the root ref' do
          expect(subject).to eq("/-/snippets/#{personal_snippet.id}/raw/#{expected_ref}/#{blob.path}")
        end
      end
    end

    describe '#gitlab_raw_snippet_url' do
      it 'returns the raw personal snippet url' do
        expect(gitlab_raw_snippet_url(personal_snippet)).to eq("http://test.host/-/snippets/#{personal_snippet.id}/raw")
      end

      it 'returns the raw project snippet url' do
        expect(gitlab_raw_snippet_url(project_snippet)).to eq("http://test.host/#{project_snippet.project.full_path}/-/snippets/#{project_snippet.id}/raw")
      end
    end

    describe '#gitlab_raw_snippet_blob_url' do
      let(:blob) { snippet.blobs.first }
      let(:ref)  { 'snippet-test-ref' }
      let(:args) { {} }
      let(:path) { blob.path }

      subject { gitlab_raw_snippet_blob_url(snippet, path, ref, **args) }

      it_behaves_like 'snippet blob raw url'

      context 'when an argument is set' do
        let(:args) { { inline: true } }
        let(:snippet) { personal_snippet }

        it { expect(subject).to eq("http://test.host/-/snippets/#{snippet.id}/raw/#{ref}/#{path}?inline=true") }
      end

      context 'without a ref' do
        let(:snippet) { personal_snippet }
        let(:ref) { nil }
        let(:expected_ref) { snippet.repository.root_ref }

        it 'uses the root ref' do
          expect(subject).to eq("http://test.host/-/snippets/#{snippet.id}/raw/#{expected_ref}/#{path}")
        end

        context 'when snippet does not have a repository' do
          let(:snippet) { create(:personal_snippet) }
          let(:path) { 'example' }
          let(:expected_ref) { Gitlab::DefaultBranch.value }

          it 'uses the instance deafult branch' do
            expect(subject).to eq("http://test.host/-/snippets/#{snippet.id}/raw/#{expected_ref}/#{path}")
          end
        end
      end
    end

    describe '#gitlab_raw_snippet_url' do
      it 'returns the raw personal snippet url' do
        expect(gitlab_raw_snippet_url(personal_snippet)).to eq("http://test.host/-/snippets/#{personal_snippet.id}/raw")
      end

      it 'returns the raw project snippet url' do
        expect(gitlab_raw_snippet_url(project_snippet)).to eq("http://test.host/#{project_snippet.project.full_path}/-/snippets/#{project_snippet.id}/raw")
      end
    end

    describe '#gitlab_snippet_notes_path' do
      it 'returns the notes path for the personal snippet' do
        expect(gitlab_snippet_notes_path(personal_snippet)).to eq("/-/snippets/#{personal_snippet.id}/notes")
      end
    end

    describe '#gitlab_snippet_notes_url' do
      it 'returns the notes url for the personal snippet' do
        expect(gitlab_snippet_notes_url(personal_snippet)).to eq("http://test.host/-/snippets/#{personal_snippet.id}/notes")
      end
    end

    describe '#gitlab_snippet_note_path' do
      it 'returns the note path for the personal snippet' do
        expect(gitlab_snippet_note_path(personal_snippet, note)).to eq("/-/snippets/#{personal_snippet.id}/notes/#{note.id}")
      end
    end

    describe '#gitlab_snippet_note_url' do
      it 'returns the note url for the personal snippet' do
        expect(gitlab_snippet_note_url(personal_snippet, note)).to eq("http://test.host/-/snippets/#{personal_snippet.id}/notes/#{note.id}")
      end
    end

    describe '#gitlab_toggle_award_emoji_snippet_note_path' do
      it 'returns the note award emoji path for the personal snippet' do
        expect(gitlab_toggle_award_emoji_snippet_note_path(personal_snippet, note)).to eq("/-/snippets/#{personal_snippet.id}/notes/#{note.id}/toggle_award_emoji")
      end
    end

    describe '#gitlab_toggle_award_emoji_snippet_note_url' do
      it 'returns the note award emoji url for the personal snippet' do
        expect(gitlab_toggle_award_emoji_snippet_note_url(personal_snippet, note)).to eq("http://test.host/-/snippets/#{personal_snippet.id}/notes/#{note.id}/toggle_award_emoji")
      end
    end

    describe '#gitlab_toggle_award_emoji_snippet_path' do
      it 'returns the award emoji path for the personal snippet' do
        expect(gitlab_toggle_award_emoji_snippet_path(personal_snippet)).to eq("/-/snippets/#{personal_snippet.id}/toggle_award_emoji")
      end
    end

    describe '#gitlab_toggle_award_emoji_snippet_url' do
      it 'returns the award url for the personal snippet' do
        expect(gitlab_toggle_award_emoji_snippet_url(personal_snippet)).to eq("http://test.host/-/snippets/#{personal_snippet.id}/toggle_award_emoji")
      end
    end

    describe '#gitlab_dashboard_snippets_path' do
      it 'returns the personal snippets dashboard path' do
        expect(gitlab_dashboard_snippets_path(personal_snippet)).to eq("/dashboard/snippets")
      end

      it 'returns the project snippets dashboard path' do
        expect(gitlab_dashboard_snippets_path(project_snippet)).to eq("/#{project_snippet.project.full_path}/-/snippets")
      end
    end
  end

  context 'wikis' do
    let(:wiki) { create(:project_wiki) }

    describe '#wiki_page_path' do
      it 'returns the url for the wiki page' do
        expect(wiki_page_path(wiki, 'page')).to eq("/#{wiki.project.full_path}/-/wikis/page")
      end
    end
  end

  context 'releases' do
    let(:release) { create(:release) }

    describe '#release_url' do
      it 'returns the url for the release page' do
        expect(release_url(release)).to eq("http://test.host/#{release.project.full_path}/-/releases/#{release.tag}")
      end
    end
  end

  context 'GraphQL ETag paths' do
    context 'with pipelines' do
      let(:sha) { 'b08774cb1a11ecdc27a82c5f444a69ea7e038ede' }
      let(:pipeline) { double(id: 5 ) }

      it 'returns an ETag path for a pipeline sha' do
        expect(graphql_etag_pipeline_sha_path(sha)).to eq('/api/graphql:pipelines/sha/b08774cb1a11ecdc27a82c5f444a69ea7e038ede')
      end

      it 'returns an ETag path for pipelines' do
        expect(graphql_etag_pipeline_path(pipeline)).to eq('/api/graphql:pipelines/id/5')
      end
    end
  end
end
