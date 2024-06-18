# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples "no multiple viewers" do |commit_ref|
  let(:ref) { commit_ref }

  it "does not display multiple diff viewers" do
    expect(page).not_to have_selector '[data-diff-toggle-entity]'
  end
end

RSpec.describe 'Multiple view Diffs', :js, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }

  let(:ref) { '5d6ed1503801ca9dc28e95eeb85a7cf863527aee' }
  let(:path) { project_commit_path(project, ref) }
  let(:feature_flag_on) { false }

  before do
    visit path

    wait_for_all_requests
  end

  context 'diff does not include ipynb' do
    it_behaves_like "no multiple viewers", 'ddd0f15ae83993f5cb66a927a28673882e99100b'

    context 'and in inline diff' do
      let(:ref) { '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51' }

      it 'does not change display for non-ipynb' do
        expect(page).to have_selector line_with_content('new', 1)
      end
    end

    context 'and in parallel diff' do
      let(:ref) { '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51' }

      it 'does not change display for non-ipynb' do
        page.find('#parallel-diff-btn').click

        expect(page).to have_selector line_with_content('new', 1)
      end
    end
  end

  context 'opening a diff with ipynb' do
    it 'loads the raw diff as hidden' do
      diff = page.find('.diff-file, .file-holder', match: :first)

      expect(diff).not_to have_selector '[data-diff-toggle-entity="rawViewer"]'
      expect(diff).to have_selector '[data-diff-toggle-entity="renderedViewer"]'

      expect(classes_for_element(diff, 'rawViewer', visible: false)).to include('hidden')
      expect(classes_for_element(diff, 'renderedViewer')).not_to include('hidden')

      expect(classes_for_element(diff, 'renderedButton')).to include('selected')
      expect(classes_for_element(diff, 'rawButton')).not_to include('selected')
    end

    it 'displays the raw diff and hides after selection changes' do
      diff = page.find('.diff-file, .file-holder', match: :first)
      diff.find('[data-diff-toggle-entity="rawButton"]').click

      expect(diff).to have_selector '[data-diff-toggle-entity="rawViewer"]'
      expect(diff).not_to have_selector '[data-diff-toggle-entity="renderedViewer"]'

      expect(classes_for_element(diff, 'renderedButton')).not_to include('selected')
      expect(classes_for_element(diff, 'rawButton')).to include('selected')
    end

    it 'transforms the diff' do
      diff = page.find('.diff-file, .file-holder', match: :first)

      expect(diff['innerHTML']).to include('%% Cell type:markdown id:0aac5da7-745c-4eda-847a-3d0d07a1bb9b tags:')
    end

    context 'on parallel view' do
      before do
        page.find('#parallel-diff-btn').click
      end

      it 'lines without mapping cannot receive comments', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/452347' do
        expect(page).not_to have_selector('td.line_content.nomappinginraw ~ td.diff-line-num > .add-diff-note')
        expect(page).to have_selector('td.line_content:not(.nomappinginraw) ~ td.diff-line-num > .add-diff-note')
      end

      it 'lines numbers without mapping are empty', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/452350' do
        expect(page).not_to have_selector('td.nomappinginraw + td.diff-line-num')
        expect(page).to have_selector('td.nomappinginraw + td.diff-line-num', visible: false)
      end

      it 'transforms the diff' do
        diff = page.find('.diff-file, .file-holder', match: :first)

        expect(diff['innerHTML']).to include('%% Cell type:markdown id:0aac5da7-745c-4eda-847a-3d0d07a1bb9b tags:')
      end
    end

    context 'on inline view' do
      it 'lines without mapping cannot receive comments' do
        expect(page).not_to have_selector('tr.line_holder[class$="nomappinginraw"] > td.diff-line-num > .add-diff-note')
        expect(page).to have_selector('tr.line_holder:not([class$="nomappinginraw"]) > td.diff-line-num > .add-diff-note')
      end

      it 'lines numbers without mapping are empty' do
        elements = page.all('tr.line_holder[class$="nomappinginraw"] > td.diff-line-num').map { |e| e.text(:all) }

        expect(elements).to all(be == "")
      end
    end
  end

  def classes_for_element(node, data_diff_entity, visible: true)
    node.find("[data-diff-toggle-entity=\"#{data_diff_entity}\"]", visible: visible)[:class]
  end

  def line_with_content(old_or_new, line_number)
    "td.#{old_or_new}_line.diff-line-num[data-linenumber=\"#{line_number}\"] > a[data-linenumber=\"#{line_number}\"]"
  end
end
