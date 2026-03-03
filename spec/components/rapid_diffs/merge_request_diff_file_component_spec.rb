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

  describe 'extra_file_data' do
    it 'includes code_review_id in file_data' do
      render_component

      diff_file_element = page.find('diff-file')
      file_data = Gitlab::Json.parse(diff_file_element['data-file-data'])
      expect(file_data['code_review_id']).to eq(diff_file.code_review_id)
    end
  end

  describe 'viewed toggle' do
    let(:code_review_id) { 'abc123def456' }

    before do
      allow(diff_file).to receive(:code_review_id).and_return(code_review_id)
    end

    it 'renders viewed checkbox' do
      render_component

      expect(page).to have_css('[data-viewed-checkbox]')
      expect(page).to have_text('Viewed')
    end

    it 'renders checkbox with correct id' do
      render_component

      expect(page).to have_css("input[name='code-review-#{code_review_id[0..8]}']")
    end

    it 'includes code_review_id in extra_options' do
      render_component

      diff_file_element = page.find('diff-file')
      expect(diff_file_element['data-code-review-id']).to eq(code_review_id)
    end

    context 'when code_review_id is not present' do
      before do
        allow(diff_file).to receive(:code_review_id).and_return(nil)
      end

      it 'does not render viewed checkbox' do
        render_component

        expect(page).not_to have_css('[data-viewed-checkbox]')
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
