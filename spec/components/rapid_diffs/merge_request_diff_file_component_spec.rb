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
      repository: repository
    )
  end

  describe 'rendering' do
    it 'renders additional options in the header menu' do
      render_component

      options_menu_items = Gitlab::Json.parse(page.find('script', visible: false).text)

      expect(options_menu_items.length).to eq(2)
      expect(options_menu_items[0]['text']).to eq('View file @ abc123')
      expect(options_menu_items[1]['text']).to eq('Edit in single-file editor')
      expect(options_menu_items[1]['href']).to include("#{edit_path_base}#{merge_request.iid}")
    end
  end

  def render_component(**args)
    render_inline(described_class.new(diff_file:, merge_request:, **args))
  end
end
