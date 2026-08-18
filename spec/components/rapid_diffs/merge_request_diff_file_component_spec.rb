# frozen_string_literal: true

require "spec_helper"

require_relative './shared'

RSpec.describe RapidDiffs::MergeRequestDiffFileComponent, type: :component, feature_category: :code_review_workflow do
  include_context "with diff file component tests"

  let(:merge_request) { build(:merge_request, source_project: project, target_project: project) }
  let(:conflict_resolution_path) { nil }
  let(:can_merge) { true }
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

        expect(options_menu_items[1]['text']).to eq('Edit single file')
        expect(options_menu_items[1]['href']).to include("#{edit_path_base}#{merge_request.iid}")
      end

      context 'when merge request is from a fork' do
        let(:source_project) { build(:project) }
        let(:fork_merge_request) do
          build(:merge_request, source_project: source_project, target_project: project).tap do |mr|
            allow(mr).to receive_messages(source_branch: 'feature-branch', iid: 123)
          end
        end

        it 'uses source_project for the edit path, not the target project' do
          render_inline(described_class.new(diff_file: diff_file, merge_request: fork_merge_request, plain_view: true))

          options_menu_items = Gitlab::Json.parse(page.find('script', visible: false).text)

          expect(options_menu_items[1]['href']).to include(source_project.full_path)
        end
      end

      context 'when the source project no longer exists' do
        before do
          allow(merge_request).to receive(:source_project).and_return(nil)
        end

        it 'renders without raising and omits the edit option', :aggregate_failures do
          expect { render_component }.not_to raise_error

          options_menu_items = Gitlab::Json.parse(page.find('script', visible: false).text)

          expect(options_menu_items.pluck('text')).not_to include('Edit in single-file editor')
        end
      end

      context 'when the file is stored externally' do
        before do
          allow(diff_file).to receive(:stored_externally?).and_return(true)
        end

        it 'omits the edit option' do
          render_component

          options_menu_items = Gitlab::Json.parse(page.find('script', visible: false).text)

          expect(options_menu_items.pluck('text')).not_to include('Edit in single-file editor')
        end
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

    it 'includes blob_raw_path in file_data' do
      render_component

      diff_file_element = page.find('diff-file')
      file_data = Gitlab::Json.parse(diff_file_element['data-file-data'])
      expect(file_data['blob_raw_path']).to include('/raw/')
      expect(file_data['blob_raw_path']).to include(content_sha)
      expect(file_data['blob_raw_path']).to include('path/to/file.rb')
    end

    it 'merges externally-provided extra_file_data into file_data' do
      render_component(extra_file_data: { show_whitespace: true, custom_key: 'custom_value' })

      diff_file_element = page.find('diff-file')
      file_data = Gitlab::Json.parse(diff_file_element['data-file-data'])
      expect(file_data['show_whitespace']).to be(true)
      expect(file_data['custom_key']).to eq('custom_value')
      expect(file_data['code_review_id']).to eq(diff_file.code_review_id)
    end

    it 'includes the diff file refs in file_data' do
      allow(diff_file).to receive(:diff_refs).and_return(
        Gitlab::Diff::DiffRefs.new(base_sha: 'base123', start_sha: 'start456', head_sha: 'head789')
      )

      render_component

      diff_file_element = page.find('diff-file')
      file_data = Gitlab::Json.parse(diff_file_element['data-file-data'])
      expect(file_data['diff_refs']).to eq(
        'base_sha' => 'base123',
        'start_sha' => 'start456',
        'head_sha' => 'head789'
      )
    end

    it 'omits diff_refs when the diff file has none' do
      allow(diff_file).to receive(:diff_refs).and_return(nil)

      render_component

      diff_file_element = page.find('diff-file')
      file_data = Gitlab::Json.parse(diff_file_element['data-file-data'])
      expect(file_data).not_to have_key('diff_refs')
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

  describe 'file discussions container' do
    it 'renders the container inside the before_body slot' do
      render_component

      details = page.find('details[data-file-body]')
      expect(details).to have_css('[data-file-discussions]')
    end
  end

  describe 'file comment button' do
    it 'renders a disabled comment button' do
      render_component

      button = page.find('[data-testid="comment-files-button"]')
      expect(button[:disabled]).to eq('disabled')
      expect(button[:'aria-label']).to eq('Comment on this file')
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

  describe 'conflict resolution message' do
    before do
      allow(diff_file).to receive(:conflict).and_return(:both_modified)
    end

    context 'when the user cannot merge' do
      let(:can_merge) { false }
      let(:conflict_resolution_path) { '/group/project/-/merge_requests/123/conflicts' }

      it 'asks to reach out to someone with write access, without action controls' do
        render_component

        expect(page).to have_text('Ask someone with write access to resolve it.')
        expect(page).not_to have_link('resolve conflicts on GitLab')
        expect(page).not_to have_button('resolve them locally')
      end
    end

    context 'when the user can merge and a resolution path is available' do
      let(:conflict_resolution_path) { '/group/project/-/merge_requests/123/conflicts' }

      it 'links to the conflict resolution page and offers local resolution' do
        render_component

        expect(page.find_link('resolve conflicts on GitLab')[:href]).to eq(conflict_resolution_path)
        expect(page.find_button('resolve them locally')['data-click']).to eq('resolveConflictsLocally')
      end
    end

    context 'when the user can merge but no resolution path is available' do
      let(:conflict_resolution_path) { nil }

      it 'offers local resolution only' do
        render_component

        expect(page).not_to have_link('resolve conflicts on GitLab')
        expect(page.find_button('resolve them locally')['data-click']).to eq('resolveConflictsLocally')
      end
    end
  end

  def render_component(**args)
    render_inline(described_class.new(
      diff_file: diff_file, merge_request: merge_request,
      conflict_resolution_path: conflict_resolution_path, can_merge: can_merge, plain_view: true, **args
    ))
  end
end
