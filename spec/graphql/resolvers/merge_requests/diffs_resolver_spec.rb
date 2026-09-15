# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::MergeRequests::DiffsResolver, feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  let(:args) { {} }

  subject(:resolved) do
    resolve(
      described_class,
      obj: merge_request,
      args: args,
      ctx: { current_user: developer },
      field_opts: {
        calls_gitaly: true,
        connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension
      }
    )
  end

  it { expect(described_class).to have_nullable_graphql_type(Types::MergeRequests::DiffConnectionType) }

  describe '#resolve' do
    it 'returns the per-file diffs' do
      expect(resolved.to_a).to all(be_a(Gitlab::Git::Diff))
    end

    context 'when the merge request has no diff record' do
      let(:merge_request) { create(:merge_request, :skip_diff_creation) }
      let(:developer) { create(:user, developer_of: merge_request.source_project) }

      it 'returns an empty connection' do
        expect(resolved.to_a).to be_empty
      end
    end

    context 'when the cursor is invalid' do
      using RSpec::Parameterized::TableSyntax

      where(:cursor_value) do
        ['not-a-page', '0', '-1']
      end

      with_them do
        let(:args) { { after: GitlabSchema.cursor_encoder.encode(cursor_value) } }

        it 'creates an argument error' do
          expect_graphql_error_to_be_created(
            Gitlab::Graphql::Errors::ArgumentError, 'Please provide a valid cursor'
          ) { resolved }
        end
      end
    end

    context 'when the diff exceeds the collection size limits' do
      before do
        stub_application_setting(diff_max_lines: 150, diff_max_files: 1000)
      end

      it 'collapses the patch text of the files past the limit' do
        collapsed = resolved.to_a.select(&:collapsed?)

        expect(collapsed).not_to be_empty
        expect(collapsed.map(&:diff)).to all(be_empty)
      end

      it 'does not flag the connection as overflowed when files are only collapsed' do
        expect(resolved.items.overflow).to be(false)
      end

      context 'when expanded is true' do
        let(:args) { { expanded: true } }

        it 'returns the patch text instead of collapsing' do
          expect(resolved.to_a).not_to be_empty
          expect(resolved.to_a.select(&:collapsed?)).to be_empty
        end

        it 'flags the connection as overflowed when files are omitted past the limit' do
          expect(resolved.items.overflow).to be(true)
        end
      end
    end
  end
end
