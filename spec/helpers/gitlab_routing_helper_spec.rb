# frozen_string_literal: true

require 'spec_helper'

describe GitlabRoutingHelper do
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

      expect(preview_markdown_path(nil)).to eq("/snippets/preview_markdown")
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

  context 'snippets' do
    let_it_be(:personal_snippet) { create(:personal_snippet) }
    let_it_be(:project_snippet) { create(:project_snippet) }
    let_it_be(:note) { create(:note_on_personal_snippet, noteable: personal_snippet) }

    describe '#snippet_path' do
      it 'returns the personal snippet path' do
        expect(snippet_path(personal_snippet)).to eq("/snippets/#{personal_snippet.id}")
      end

      it 'returns the project snippet path' do
        expect(snippet_path(project_snippet)).to eq("/#{project_snippet.project.full_path}/snippets/#{project_snippet.id}")
      end
    end

    describe '#snippet_url' do
      it 'returns the personal snippet url' do
        expect(snippet_url(personal_snippet)).to eq("#{Settings.gitlab['url']}/snippets/#{personal_snippet.id}")
      end

      it 'returns the project snippet url' do
        expect(snippet_url(project_snippet)).to eq("#{Settings.gitlab['url']}/#{project_snippet.project.full_path}/snippets/#{project_snippet.id}")
      end
    end

    describe '#raw_snippet_path' do
      it 'returns the raw personal snippet path' do
        expect(raw_snippet_path(personal_snippet)).to eq("/snippets/#{personal_snippet.id}/raw")
      end

      it 'returns the raw project snippet path' do
        expect(raw_snippet_path(project_snippet)).to eq("/#{project_snippet.project.full_path}/snippets/#{project_snippet.id}/raw")
      end
    end

    describe '#raw_snippet_url' do
      it 'returns the raw personal snippet url' do
        expect(raw_snippet_url(personal_snippet)).to eq("#{Settings.gitlab['url']}/snippets/#{personal_snippet.id}/raw")
      end

      it 'returns the raw project snippet url' do
        expect(raw_snippet_url(project_snippet)).to eq("#{Settings.gitlab['url']}/#{project_snippet.project.full_path}/snippets/#{project_snippet.id}/raw")
      end
    end

    describe '#snippet_notes_path' do
      it 'returns the notes path for the personal snippet' do
        expect(snippet_notes_path(personal_snippet)).to eq("/snippets/#{personal_snippet.id}/notes")
      end
    end

    describe '#snippet_notes_url' do
      it 'returns the notes url for the personal snippet' do
        expect(snippet_notes_url(personal_snippet)).to eq("#{Settings.gitlab['url']}/snippets/#{personal_snippet.id}/notes")
      end
    end

    describe '#snippet_note_path' do
      it 'returns the note path for the personal snippet' do
        expect(snippet_note_path(personal_snippet, note)).to eq("/snippets/#{personal_snippet.id}/notes/#{note.id}")
      end
    end

    describe '#snippet_note_url' do
      it 'returns the note url for the personal snippet' do
        expect(snippet_note_url(personal_snippet, note)).to eq("#{Settings.gitlab['url']}/snippets/#{personal_snippet.id}/notes/#{note.id}")
      end
    end

    describe '#toggle_award_emoji_snippet_note_path' do
      it 'returns the note award emoji path for the personal snippet' do
        expect(toggle_award_emoji_snippet_note_path(personal_snippet, note)).to eq("/snippets/#{personal_snippet.id}/notes/#{note.id}/toggle_award_emoji")
      end
    end

    describe '#toggle_award_emoji_snippet_note_url' do
      it 'returns the note award emoji url for the personal snippet' do
        expect(toggle_award_emoji_snippet_note_url(personal_snippet, note)).to eq("#{Settings.gitlab['url']}/snippets/#{personal_snippet.id}/notes/#{note.id}/toggle_award_emoji")
      end
    end

    describe '#toggle_award_emoji_snippet_path' do
      it 'returns the award emoji path for the personal snippet' do
        expect(toggle_award_emoji_snippet_path(personal_snippet)).to eq("/snippets/#{personal_snippet.id}/toggle_award_emoji")
      end
    end

    describe '#toggle_award_emoji_snippet_url' do
      it 'returns the award url for the personal snippet' do
        expect(toggle_award_emoji_snippet_url(personal_snippet)).to eq("#{Settings.gitlab['url']}/snippets/#{personal_snippet.id}/toggle_award_emoji")
      end
    end
  end
end
