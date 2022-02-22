# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples "no multiple viewers" do |commit_ref|
  let(:ref) { commit_ref }

  it "does not display multiple diff viewers" do
    expect(page).not_to have_selector '[data-diff-toggle-entity]'
  end
end

RSpec.describe 'Multiple view Diffs', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
  let(:ref) { '5d6ed1503801ca9dc28e95eeb85a7cf863527aee' }
  let(:path) { project_commit_path(project, ref) }
  let(:feature_flag_on) { false }

  before do
    stub_feature_flags(rendered_diffs_viewer: feature_flag_on ? project : false)

    visit path

    wait_for_all_requests
  end

  context 'when :rendered_diffs_viewer is off' do
    context 'and diff does not have ipynb' do
      include_examples "no multiple viewers", 'ddd0f15ae83993f5cb66a927a28673882e99100b'
    end

    context 'and diff has ipynb' do
      include_examples "no multiple viewers", '5d6ed1503801ca9dc28e95eeb85a7cf863527aee'

      it 'shows the transformed diff' do
        diff = page.find('.diff-file, .file-holder', match: :first)

        expect(diff['innerHTML']).to include('%% Cell type:markdown id:0aac5da7-745c-4eda-847a-3d0d07a1bb9b tags:')
      end
    end
  end

  context 'when :rendered_diffs_viewer is on' do
    let(:feature_flag_on) { true }

    context 'and diff does not include ipynb' do
      include_examples "no multiple viewers", 'ddd0f15ae83993f5cb66a927a28673882e99100b'
    end

    context 'and opening a diff with ipynb' do
      context 'but the changes are not renderable' do
        include_examples "no multiple viewers", 'a867a602d2220e5891b310c07d174fbe12122830'
      end

      it 'loads the rendered diff as hidden' do
        diff = page.find('.diff-file, .file-holder', match: :first)

        expect(diff).to have_selector '[data-diff-toggle-entity="toHide"]'
        expect(diff).not_to have_selector '[data-diff-toggle-entity="toShow"]'

        expect(classes_for_element(diff, 'toShow', visible: false)).to include('hidden')
        expect(classes_for_element(diff, 'toHide')).not_to include('hidden')

        expect(classes_for_element(diff, 'toHideBtn')).to include('selected')
        expect(classes_for_element(diff, 'toShowBtn')).not_to include('selected')
      end

      it 'displays the rendered diff and hides after selection changes' do
        diff = page.find('.diff-file, .file-holder', match: :first)
        diff.find('[data-diff-toggle-entity="toShowBtn"]').click

        expect(diff).to have_selector '[data-diff-toggle-entity="toShow"]'
        expect(diff).not_to have_selector '[data-diff-toggle-entity="toHide"]'

        expect(classes_for_element(diff, 'toHideBtn')).not_to include('selected')
        expect(classes_for_element(diff, 'toShowBtn')).to include('selected')
      end
    end
  end

  def classes_for_element(node, data_diff_entity, visible: true)
    node.find("[data-diff-toggle-entity=\"#{data_diff_entity}\"]", visible: visible)[:class]
  end
end
