# frozen_string_literal: true

require "spec_helper"

require_relative './shared'

RSpec.describe RapidDiffs::MergeRequestDiffFileComponent, type: :component, feature_category: :code_review_workflow do
  include_context "with diff file component tests"

  let(:merge_request) { build(:merge_request, source_project: project, target_project: project) }
  let(:content_sha) { 'abc123' }
  let(:edit_path_base) { '/-/edit/feature-branch/path/to/file.rb?from_merge_request_iid=' }

  before do
    allow(diff_file).to receive(:repository).and_return(repository)
    allow(repository).to receive(:commit).with(RepoHelpers.sample_commit.id).and_return(sample_commit)
    allow(merge_request).to receive_messages(
      source_branch: 'feature-branch',
      iid: 123
    )
    allow(diff_file).to receive_messages(
      new_path: 'path/to/file.rb',
      content_sha: content_sha,
      repository: repository,
      conflict: nil
    )
  end

  describe 'header menu options' do
    context 'with text diff file' do
      before do
        allow(diff_file).to receive(:text?).and_return(true)
      end

      it 'renders additional options' do
        render_component

        options_menu_items = Gitlab::Json.parse(page.find('script', visible: false).text)

        expect(options_menu_items[1]['text']).to eq('Edit in single-file editor')
        expect(options_menu_items[1]['href']).to include("#{edit_path_base}#{merge_request.iid}")
      end
    end
  end

  describe 'conflict message' do
    where(:conflict_type, :expected_message) do
      [
        [:both_modified, 'This file was modified in both the source and target branches.'],
        [:modified_source_removed_target,
          'This file was modified in the source branch, but removed in the target branch.'],
        [:modified_target_removed_source,
          'This file was removed in the source branch, but modified in the target branch.'],
        [:renamed_same_file, 'This file was renamed differently in the source and target branches.'],
        [:removed_source_renamed_target,
          'This file was removed in the source branch, but renamed in the target branch.'],
        [:removed_target_renamed_source,
          'This file was renamed in the source branch, but removed in the target branch.'],
        [:both_added, 'This file was added both in the source and target branches, but with different contents.'],
        [:unknown_type, 'Unknown conflict']
      ]
    end

    with_them do
      before do
        allow(diff_file).to receive(:conflict).and_return(conflict_type)
      end

      it 'renders the appropriate conflict message' do
        render_component

        expect(page).to have_text(expected_message)
      end
    end

    context 'when there is no conflict' do
      before do
        allow(diff_file).to receive(:conflict).and_return(nil)
      end

      it 'does not render conflict message' do
        render_component

        expect(page).not_to have_text('Conflict:')
      end
    end
  end

  def render_component(**args)
    render_inline(described_class.new(diff_file: diff_file, merge_request: merge_request, plain_view: true, **args))
  end
end
