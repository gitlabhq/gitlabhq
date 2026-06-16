# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Discussion'], feature_category: :code_review_workflow do
  include GraphqlHelpers

  it 'exposes the expected fields' do
    expected_fields = %i[
      created_at
      id
      notes
      reply_id
      resolvable
      resolved
      resolved_at
      resolved_by
      noteable
      truncated_diff_lines
      user_permissions
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_note) }

  describe '.authorization_scopes' do
    it 'allows ai_workflows scope token' do
      expect(described_class.authorization_scopes).to include(:ai_workflows)
    end
  end

  describe '#truncated_diff_lines' do
    # rubocop:disable RSpec/FactoryBot/AvoidCreate -- a diff note needs a persisted note on a real repository
    let_it_be(:project) { create(:project, :public, :repository) }
    let_it_be(:diff_note) { create(:diff_note_on_merge_request, project: project) }
    # rubocop:enable RSpec/FactoryBot/AvoidCreate

    it 'returns the highlighted diff lines above the note, up to the commented line', :aggregate_failures do
      lines = batch_sync do
        resolve_field(:truncated_diff_lines, diff_note.to_discussion, current_user: diff_note.author)
      end

      expect(lines).to be_present
      expect(lines.last.new_line).to eq(diff_note.position.new_line)
    end

    context 'when the discussion is not a diff discussion' do
      # rubocop:disable RSpec/FactoryBot/AvoidCreate -- to_discussion needs a persisted note
      # Reuse the diff note's merge request so a second MR isn't opened on the
      # same source branch (which the factory would reject).
      let_it_be(:note) { create(:note_on_merge_request, noteable: diff_note.noteable, project: project) }
      # rubocop:enable RSpec/FactoryBot/AvoidCreate

      it 'returns nil' do
        lines = batch_sync do
          resolve_field(:truncated_diff_lines, note.to_discussion, current_user: note.author)
        end

        expect(lines).to be_nil
      end
    end

    context 'with several diff discussions resolved together' do
      # rubocop:disable RSpec/FactoryBot/AvoidCreate -- diff notes need persisted notes on a real repository
      let_it_be(:merge_request) { create(:merge_request) }
      let_it_be(:note_a) do
        create(:diff_note_on_merge_request, noteable: merge_request, project: merge_request.project)
      end

      let_it_be(:note_b) do
        create(:diff_note_on_merge_request, noteable: merge_request, project: merge_request.project,
          position: build(:text_diff_position, :added, file: 'files/ruby/regex.rb', new_line: 22,
            diff_refs: merge_request.diff_refs))
      end
      # rubocop:enable RSpec/FactoryBot/AvoidCreate

      # Reload so `discussions_diffs` is unmemoized and the batch preload builds a
      # fresh FileCollection we can assert against.
      let(:discussions) { MergeRequest.find(merge_request.id).discussions.select(&:diff_discussion?) }

      it 'highlights the diffs once for the whole connection instead of per discussion', :aggregate_failures do
        expect(discussions.size).to eq(2)

        expect_next_instance_of(Gitlab::DiscussionsDiff::FileCollection) do |collection|
          expect(collection).to receive(:load_highlight).once.and_call_original
        end

        lines = batch_sync do
          discussions.map do |discussion|
            resolve_field(:truncated_diff_lines, discussion, current_user: merge_request.author)
          end
        end

        expect(lines).to all(be_present)
      end
    end
  end
end
