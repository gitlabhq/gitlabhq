# frozen_string_literal: true

require "spec_helper"

RSpec.describe NotesHelper, feature_category: :team_planning do
  include RepoHelpers

  let_it_be(:owner) { create(:owner) }
  let_it_be(:group) { create(:group, owners: owner) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }

  let_it_be(:owner_note) { create(:note, author: owner, project: project) }
  let_it_be(:maintainer_note) { create(:note, author: maintainer, project: project) }
  let_it_be(:reporter_note) { create(:note, author: reporter, project: project) }

  let!(:notes) { [owner_note, maintainer_note, reporter_note] }

  describe '#note_target_title' do
    context 'note does not exist' do
      it 'returns nil' do
        expect(helper.note_target_title(nil)).to be_blank
      end
    end

    context 'target does not exist' do
      it 'returns nil' do
        note = Note.new
        expect(helper.note_target_title(note)).to be_blank
      end
    end

    context 'when given a design target' do
      it 'returns nil' do
        note = build_stubbed(:note_on_design)
        expect(helper.note_target_title(note)).to be_blank
      end
    end

    context 'when given a non-design target' do
      it 'returns the issue title' do
        issue = build_stubbed(:issue, title: 'Issue 1')
        note = build_stubbed(:note, noteable: issue)
        expect(helper.note_target_title(note)).to eq('Issue 1')
      end
    end
  end

  describe '#discussion_path' do
    let_it_be(:project) { create(:project, :repository) }

    let(:anchor) { discussion.line_code }

    context 'for a merge request discusion' do
      let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project, importing: true) }
      let_it_be(:merge_request_diff1) { merge_request.merge_request_diffs.create!(head_commit_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
      let_it_be(:merge_request_diff2) { merge_request.merge_request_diffs.create!(head_commit_sha: nil) }
      let_it_be(:merge_request_diff3) { merge_request.merge_request_diffs.create!(head_commit_sha: '5937ac0a7beb003549fc5fd26fc247adbce4a52e') }

      context 'for a diff discussion' do
        context 'when the discussion is active' do
          let(:discussion) { create(:diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion }

          it 'returns the diff path with the line code' do
            expect(helper.discussion_path(discussion)).to eq(diffs_project_merge_request_path(project, merge_request, anchor: discussion.line_code))
          end
        end

        context 'when the discussion is on an older merge request version' do
          let(:position) do
            build(:text_diff_position, :added,
              file: ".gitmodules",
              new_line: 4,
              diff_refs: merge_request_diff1.diff_refs
            )
          end

          let(:diff_note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project, position: position) }
          let(:discussion) { diff_note.to_discussion }

          before do
            diff_note.position = diff_note.original_position
            diff_note.save!
          end

          it 'returns the diff version path with the line code' do
            expect(helper.discussion_path(discussion)).to eq(diffs_project_merge_request_path(project, merge_request, diff_id: merge_request_diff1, anchor: discussion.line_code))
          end
        end

        context 'when the discussion is on a comparison between merge request versions' do
          let(:position) do
            build(:text_diff_position,
              file: ".gitmodules",
              old_line: 4,
              new_line: 4,
              diff_refs: ::MergeRequests::MergeRequestDiffComparison
                          .new(merge_request_diff3)
                          .compare_with(merge_request_diff1.head_commit_sha)
                          .diff_refs
            )
          end

          let(:diff_note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project, position: position) }
          let(:discussion) { diff_note.to_discussion }

          before do
            diff_note.position = diff_note.original_position
            diff_note.save!
          end

          it 'returns the diff version comparison path with the line code' do
            expect(helper.discussion_path(discussion)).to eq(diffs_project_merge_request_path(project, merge_request, diff_id: merge_request_diff3, start_sha: merge_request_diff1.head_commit_sha, anchor: discussion.line_code))
          end
        end

        context 'when the discussion does not have a merge request version' do
          let(:outdated_diff_note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project, diff_refs: project.commit(sample_commit.id).diff_refs) }
          let(:discussion) { outdated_diff_note.to_discussion }

          before do
            outdated_diff_note.position = outdated_diff_note.original_position
            outdated_diff_note.save!
          end

          it 'returns nil' do
            expect(helper.discussion_path(discussion)).to be_nil
          end
        end
      end

      context 'for a legacy diff discussion' do
        let(:discussion) { create(:legacy_diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion }

        context 'when the discussion is active' do
          before do
            allow(discussion).to receive(:active?).and_return(true)
          end

          it 'returns the diff path with the line code' do
            expect(helper.discussion_path(discussion)).to eq(diffs_project_merge_request_path(project, merge_request, anchor: discussion.line_code))
          end
        end

        context 'when the discussion is outdated' do
          before do
            allow(discussion).to receive(:active?).and_return(false)
          end

          it 'returns nil' do
            expect(helper.discussion_path(discussion)).to be_nil
          end
        end
      end

      context 'for a non-diff discussion' do
        let(:discussion) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project).to_discussion }

        it 'returns nil' do
          expect(helper.discussion_path(discussion)).to be_nil
        end
      end

      context 'for a contextual commit discussion' do
        let(:commit) { merge_request.commits.last }
        let(:discussion) { create(:diff_note_on_merge_request, noteable: merge_request, project: project, commit_id: commit.id).to_discussion }

        it 'returns the merge request diff discussion scoped in the commit' do
          expect(helper.discussion_path(discussion)).to eq(diffs_project_merge_request_path(project, merge_request, commit_id: commit.id, anchor: anchor))
        end
      end
    end

    context 'for a commit discussion' do
      let(:commit) { discussion.noteable }

      context 'for a diff discussion' do
        let(:discussion) { create(:diff_note_on_commit, project: project).to_discussion }

        it 'returns the commit path with the line code' do
          expect(helper.discussion_path(discussion)).to eq(project_commit_path(project, commit, anchor: anchor))
        end
      end

      context 'for a legacy diff discussion' do
        let(:discussion) { create(:legacy_diff_note_on_commit, project: project).to_discussion }

        it 'returns the commit path with the line code' do
          expect(helper.discussion_path(discussion)).to eq(project_commit_path(project, commit, anchor: anchor))
        end
      end

      context 'for a non-diff discussion' do
        let(:discussion) { create(:discussion_note_on_commit, project: project).to_discussion }

        it 'returns the commit path with the note anchor' do
          expect(helper.discussion_path(discussion)).to eq(project_commit_path(project, commit, anchor: "note_#{discussion.first_note.id}"))
        end
      end
    end
  end

  describe '#initial_notes_data' do
    it 'return initial notes data for issuable' do
      autocomplete = '/autocomplete/users'
      @project = project
      @noteable = create(:issue, project: @project)

      expect(helper.initial_notes_data(autocomplete).keys).to match_array(%i[notesUrl now diffView enableGFM])
      expect(helper.initial_notes_data(autocomplete)[:enableGFM].keys).to match(%i[emojis members issues mergeRequests vulnerabilities epics milestones labels])
    end
  end

  describe '#notes_url' do
    it 'return snippet notes path for personal snippet' do
      @snippet = create(:personal_snippet)

      expect(helper.notes_url).to eq("/-/snippets/#{@snippet.id}/notes")
    end

    it 'return project notes path for project snippet' do
      @project = project
      @snippet = create(:project_snippet, project: @project)
      @noteable = @snippet

      expect(helper.notes_url).to eq("/#{project.full_path}/noteable/project_snippet/#{@noteable.id}/notes")
    end

    it 'return project notes path for other noteables' do
      @project = project
      @noteable = create(:issue, project: @project)

      expect(helper.notes_url).to eq("/#{@project.full_path}/noteable/issue/#{@noteable.id}/notes")
    end
  end

  describe '#note_url' do
    it 'return snippet notes path for personal snippet' do
      note = create(:note_on_personal_snippet)

      expect(helper.note_url(note)).to eq("/-/snippets/#{note.noteable.id}/notes/#{note.id}")
    end

    it 'return project notes path for project snippet' do
      @project = project
      note = create(:note_on_project_snippet, project: @project)

      expect(helper.note_url(note)).to eq("/#{project.full_path}/notes/#{note.id}")
    end

    it 'return project notes path for other noteables' do
      @project = project
      note = create(:note_on_issue, project: @project)

      expect(helper.note_url(note)).to eq("/#{project.full_path}/notes/#{note.id}")
    end
  end

  describe '#form_resources' do
    it 'returns note for personal snippet' do
      @snippet = create(:personal_snippet)
      @note = create(:note_on_personal_snippet)

      expect(helper.form_resources).to eq([@note])
    end

    it 'returns namespace, project and note for project snippet' do
      @project = project
      @snippet = create(:project_snippet, project: @project)
      @note = create(:note_on_personal_snippet)

      expect(helper.form_resources).to eq([@project, @note])
    end

    it 'returns namespace, project and note path for other noteables' do
      @project = project
      @note = create(:note_on_issue, project: @project)

      expect(helper.form_resources).to eq([@project, @note])
    end
  end

  describe '#noteable_note_url' do
    let(:issue) { create(:issue, project: project) }
    let(:note) { create(:note_on_issue, noteable: issue, project: project) }

    it 'returns the noteable url with an anchor to the note' do
      expect(noteable_note_url(note)).to match("/#{project.namespace.path}/#{project.path}/-/issues/#{issue.iid}##{dom_id(note)}")
    end
  end

  describe '#notes_data' do
    let_it_be(:issue) { create(:issue, project: project) }

    let(:notes_data) { helper.notes_data(issue) }

    before do
      @project = project
      @noteable = issue

      allow(helper).to receive(:current_user).and_return(guest)
    end

    it 'includes the current notes filter for the user' do
      guest.set_notes_filter(UserPreference::NOTES_FILTERS[:only_comments], issue)

      expect(notes_data[:notesFilter]).to eq(UserPreference::NOTES_FILTERS[:only_comments])
    end

    it 'includes info about the noteable', :aggregate_failures do
      expect(notes_data[:noteableType]).to eq('issue')
      expect(notes_data[:noteableId]).to eq(issue.id)
      expect(notes_data[:projectId]).to eq(project.id)
      expect(notes_data[:groupId]).to be_nil
    end
  end
end
