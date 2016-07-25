require 'spec_helper'

describe DiffHelper do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diffs) { commit.raw_diffs }
  let(:diff) { diffs.first }
  let(:diff_refs) { [commit.parent, commit] }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs: diff_refs, repository: repository) }

  describe 'diff_view' do
    it 'returns a valid value when cookie is set' do
      helper.request.cookies[:diff_view] = 'parallel'

      expect(helper.diff_view).to eq :parallel
    end

    it 'returns a default value when cookie is invalid' do
      helper.request.cookies[:diff_view] = 'invalid'

      expect(helper.diff_view).to eq :inline
    end

    it 'returns a default value when cookie is nil' do
      expect(helper.request.cookies).to be_empty

      expect(helper.diff_view).to eq :inline
    end
  end

  describe 'diff_options' do
    it 'returns no collapse false' do
      expect(diff_options).to include(no_collapse: false)
    end

    it 'returns no collapse true if expand_all_diffs' do
      allow(controller).to receive(:params) { { expand_all_diffs: true } }
      expect(diff_options).to include(no_collapse: true)
    end

    it 'returns no collapse true if action name diff_for_path' do
      allow(controller).to receive(:action_name) { 'diff_for_path' }
      expect(diff_options).to include(no_collapse: true)
    end

    it 'should return paths if action name diff_for_path and param old path' do
      allow(controller).to receive(:params) { { old_path: 'lib/wadus.rb' } }
      allow(controller).to receive(:action_name) { 'diff_for_path' }
      expect(diff_options[:paths]).to include('lib/wadus.rb')
    end

    it 'should return paths if action name diff_for_path and param new path' do
      allow(controller).to receive(:params) { { new_path: 'lib/wadus.rb' } }
      allow(controller).to receive(:action_name) { 'diff_for_path' }
      expect(diff_options[:paths]).to include('lib/wadus.rb')
    end
  end

  describe '#diff_line_content' do
    it 'returns non breaking space when line is empty' do
      expect(diff_line_content(nil)).to eq(' &nbsp;')
    end

    it 'returns the line itself' do
      expect(diff_line_content(diff_file.diff_lines.first.text)).
        to eq('@@ -6,12 +6,18 @@ module Popen')
      expect(diff_line_content(diff_file.diff_lines.first.type)).to eq('match')
      expect(diff_file.diff_lines.first.new_pos).to eq(6)
    end
  end

  describe "#mark_inline_diffs" do
    let(:old_line) { %{abc 'def'} }
    let(:new_line) { %{abc "def"} }

    it "returns strings with marked inline diffs" do
      marked_old_line, marked_new_line = mark_inline_diffs(old_line, new_line)

      expect(marked_old_line).to eq("abc <span class='idiff left right deletion'>&#39;def&#39;</span>")
      expect(marked_old_line).to be_html_safe
      expect(marked_new_line).to eq("abc <span class='idiff left right addition'>&quot;def&quot;</span>")
      expect(marked_new_line).to be_html_safe
    end
  end

  describe "#diff_match_line" do
    let(:old_pos) { 40 }
    let(:new_pos) { 50 }
    let(:text) { 'some_text' }

    it "should generate foldable top match line for inline view with empty text by default" do
      output = diff_match_line old_pos, new_pos

      expect(output).to be_html_safe
      expect(output).to have_css "td:nth-child(1):not(.js-unfold-bottom).diff-line-num.unfold.js-unfold.old_line[data-linenumber='#{old_pos}']", text: '...'
      expect(output).to have_css "td:nth-child(2):not(.js-unfold-bottom).diff-line-num.unfold.js-unfold.new_line[data-linenumber='#{new_pos}']", text: '...'
      expect(output).to have_css 'td:nth-child(3):not(.parallel).line_content.match', text: ''
    end

    it "should allow to define text and bottom option" do
      output = diff_match_line old_pos, new_pos, text: text, bottom: true

      expect(output).to be_html_safe
      expect(output).to have_css "td:nth-child(1).diff-line-num.unfold.js-unfold.js-unfold-bottom.old_line[data-linenumber='#{old_pos}']", text: '...'
      expect(output).to have_css "td:nth-child(2).diff-line-num.unfold.js-unfold.js-unfold-bottom.new_line[data-linenumber='#{new_pos}']", text: '...'
      expect(output).to have_css 'td:nth-child(3):not(.parallel).line_content.match', text: text
    end

    it "should generate match line for parallel view" do
      output = diff_match_line old_pos, new_pos, text: text, view: :parallel

      expect(output).to be_html_safe
      expect(output).to have_css "td:nth-child(1):not(.js-unfold-bottom).diff-line-num.unfold.js-unfold.old_line[data-linenumber='#{old_pos}']", text: '...'
      expect(output).to have_css 'td:nth-child(2).line_content.match.parallel', text: text
      expect(output).to have_css "td:nth-child(3):not(.js-unfold-bottom).diff-line-num.unfold.js-unfold.new_line[data-linenumber='#{new_pos}']", text: '...'
      expect(output).to have_css 'td:nth-child(4).line_content.match.parallel', text: text
    end

    it "should allow to generate only left match line for parallel view" do
      output = diff_match_line old_pos, nil, text: text, view: :parallel

      expect(output).to be_html_safe
      expect(output).to have_css "td:nth-child(1):not(.js-unfold-bottom).diff-line-num.unfold.js-unfold.old_line[data-linenumber='#{old_pos}']", text: '...'
      expect(output).to have_css 'td:nth-child(2).line_content.match.parallel', text: text
      expect(output).not_to have_css 'td:nth-child(3)'
    end

    it "should allow to generate only right match line for parallel view" do
      output = diff_match_line nil, new_pos, text: text, view: :parallel

      expect(output).to be_html_safe
      expect(output).to have_css "td:nth-child(1):not(.js-unfold-bottom).diff-line-num.unfold.js-unfold.new_line[data-linenumber='#{new_pos}']", text: '...'
      expect(output).to have_css 'td:nth-child(2).line_content.match.parallel', text: text
      expect(output).not_to have_css 'td:nth-child(3)'
    end
  end
end
