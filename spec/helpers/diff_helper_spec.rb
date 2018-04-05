require 'spec_helper'

describe DiffHelper do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diffs) { commit.raw_diffs }
  let(:diff) { diffs.first }
  let(:diff_refs) { commit.diff_refs }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs: diff_refs, repository: repository) }

  describe 'diff_view' do
    it 'uses the view param over the cookie' do
      controller.params[:view] = 'parallel'
      helper.request.cookies[:diff_view] = 'inline'

      expect(helper.diff_view).to eq :parallel
    end

    it 'returns the default value when the view param is invalid' do
      controller.params[:view] = 'invalid'

      expect(helper.diff_view).to eq :inline
    end

    it 'returns a valid value when cookie is set' do
      helper.request.cookies[:diff_view] = 'parallel'

      expect(helper.diff_view).to eq :parallel
    end

    it 'returns the default value when cookie is invalid' do
      helper.request.cookies[:diff_view] = 'invalid'

      expect(helper.diff_view).to eq :inline
    end

    it 'returns the default value when cookie is nil' do
      expect(helper.request.cookies).to be_empty

      expect(helper.diff_view).to eq :inline
    end
  end

  describe 'diff_options' do
    it 'returns no collapse false' do
      expect(diff_options).to include(expanded: false)
    end

    it 'returns no collapse true if expanded' do
      allow(controller).to receive(:params) { { expanded: true } }
      expect(diff_options).to include(expanded: true)
    end

    it 'returns no collapse true if action name diff_for_path' do
      allow(controller).to receive(:action_name) { 'diff_for_path' }
      expect(diff_options).to include(expanded: true)
    end

    it 'returns paths if action name diff_for_path and param old path' do
      allow(controller).to receive(:params) { { old_path: 'lib/wadus.rb' } }
      allow(controller).to receive(:action_name) { 'diff_for_path' }
      expect(diff_options[:paths]).to include('lib/wadus.rb')
    end

    it 'returns paths if action name diff_for_path and param new path' do
      allow(controller).to receive(:params) { { new_path: 'lib/wadus.rb' } }
      allow(controller).to receive(:action_name) { 'diff_for_path' }
      expect(diff_options[:paths]).to include('lib/wadus.rb')
    end
  end

  describe '#diff_line_content' do
    context 'when the line is empty' do
      it 'returns a non breaking space' do
        expect(diff_line_content(nil)).to eq('&nbsp;')
      end

      it 'returns an HTML-safe string' do
        expect(diff_line_content(nil)).to be_html_safe
      end
    end

    context 'when the line is not empty' do
      context 'when the line starts with +, -, or a space' do
        it 'strips the first character' do
          expect(diff_line_content('+new line')).to eq('new line')
          expect(diff_line_content('-new line')).to eq('new line')
          expect(diff_line_content(' new line')).to eq('new line')
        end

        context 'when the line is HTML-safe' do
          it 'returns an HTML-safe string' do
            expect(diff_line_content('+new line'.html_safe)).to be_html_safe
            expect(diff_line_content('-new line'.html_safe)).to be_html_safe
            expect(diff_line_content(' new line'.html_safe)).to be_html_safe
          end
        end

        context 'when the line is not HTML-safe' do
          it 'returns a non-HTML-safe string' do
            expect(diff_line_content('+new line')).not_to be_html_safe
            expect(diff_line_content('-new line')).not_to be_html_safe
            expect(diff_line_content(' new line')).not_to be_html_safe
          end
        end
      end

      context 'when the line does not start with a +, -, or a space' do
        it 'returns the string' do
          expect(diff_line_content('@@ -6,12 +6,18 @@ module Popen')).to eq('@@ -6,12 +6,18 @@ module Popen')
        end

        context 'when the line is HTML-safe' do
          it 'returns an HTML-safe string' do
            expect(diff_line_content('@@ -6,12 +6,18 @@ module Popen'.html_safe)).to be_html_safe
          end
        end

        context 'when the line is not HTML-safe' do
          it 'returns a non-HTML-safe string' do
            expect(diff_line_content('@@ -6,12 +6,18 @@ module Popen')).not_to be_html_safe
          end
        end
      end
    end
  end

  describe "#mark_inline_diffs" do
    let(:old_line) { %{abc 'def'} }
    let(:new_line) { %{abc "def"} }

    it "returns strings with marked inline diffs" do
      marked_old_line, marked_new_line = mark_inline_diffs(old_line, new_line)

      expect(marked_old_line).to eq(%q{abc <span class="idiff left right deletion">&#39;def&#39;</span>})
      expect(marked_old_line).to be_html_safe
      expect(marked_new_line).to eq(%q{abc <span class="idiff left right addition">&quot;def&quot;</span>})
      expect(marked_new_line).to be_html_safe
    end

    context 'when given HTML' do
      it 'sanitizes it' do
        old_line = %{test.txt}
        new_line = %{<img src=x onerror=alert(document.domain)>}

        marked_old_line, marked_new_line = mark_inline_diffs(old_line, new_line)

        expect(marked_old_line).to eq(%q{<span class="idiff left right deletion">test.txt</span>})
        expect(marked_old_line).to be_html_safe
        expect(marked_new_line).to eq(%q{<span class="idiff left right addition">&lt;img src=x onerror=alert(document.domain)&gt;</span>})
        expect(marked_new_line).to be_html_safe
      end

      it 'sanitizes the entire line, not just the changes' do
        old_line = %{<img src=x onerror=alert(document.domain)>}
        new_line = %{<img src=y onerror=alert(document.domain)>}

        marked_old_line, marked_new_line = mark_inline_diffs(old_line, new_line)

        expect(marked_old_line).to eq(%q{&lt;img src=<span class="idiff left right deletion">x</span> onerror=alert(document.domain)&gt;})
        expect(marked_old_line).to be_html_safe
        expect(marked_new_line).to eq(%q{&lt;img src=<span class="idiff left right addition">y</span> onerror=alert(document.domain)&gt;})
        expect(marked_new_line).to be_html_safe
      end
    end
  end

  describe '#parallel_diff_discussions' do
    let(:discussion) { { 'abc_3_3' => 'comment' } }
    let(:diff_file) { double(line_code: 'abc_3_3') }

    before do
      helper.instance_variable_set(:@grouped_diff_discussions, discussion)
    end

    it 'does not put comments on nonewline lines' do
      left = Gitlab::Diff::Line.new('\\nonewline', 'old-nonewline', 3, 3, 3)
      right = Gitlab::Diff::Line.new('\\nonewline', 'new-nonewline', 3, 3, 3)

      result = helper.parallel_diff_discussions(left, right, diff_file)

      expect(result).to eq([nil, nil])
    end

    it 'puts comments on added lines' do
      left = Gitlab::Diff::Line.new('\\nonewline', 'old-nonewline', 3, 3, 3)
      right = Gitlab::Diff::Line.new('new line', 'new', 3, 3, 3)

      result = helper.parallel_diff_discussions(left, right, diff_file)

      expect(result).to eq([nil, 'comment'])
    end

    it 'puts comments on unchanged lines' do
      left = Gitlab::Diff::Line.new('unchanged line', nil, 3, 3, 3)
      right = Gitlab::Diff::Line.new('unchanged line', nil, 3, 3, 3)

      result = helper.parallel_diff_discussions(left, right, diff_file)

      expect(result).to eq(['comment', nil])
    end
  end

  describe "#diff_match_line" do
    let(:old_pos) { 40 }
    let(:new_pos) { 50 }
    let(:text) { 'some_text' }

    it "generates foldable top match line for inline view with empty text by default" do
      output = diff_match_line old_pos, new_pos

      expect(output).to be_html_safe
      expect(output).to have_css "td:nth-child(1):not(.js-unfold-bottom).diff-line-num.unfold.js-unfold.old_line[data-linenumber='#{old_pos}']", text: '...'
      expect(output).to have_css "td:nth-child(2):not(.js-unfold-bottom).diff-line-num.unfold.js-unfold.new_line[data-linenumber='#{new_pos}']", text: '...'
      expect(output).to have_css 'td:nth-child(3):not(.parallel).line_content.match', text: ''
    end

    it "allows to define text and bottom option" do
      output = diff_match_line old_pos, new_pos, text: text, bottom: true

      expect(output).to be_html_safe
      expect(output).to have_css "td:nth-child(1).diff-line-num.unfold.js-unfold.js-unfold-bottom.old_line[data-linenumber='#{old_pos}']", text: '...'
      expect(output).to have_css "td:nth-child(2).diff-line-num.unfold.js-unfold.js-unfold-bottom.new_line[data-linenumber='#{new_pos}']", text: '...'
      expect(output).to have_css 'td:nth-child(3):not(.parallel).line_content.match', text: text
    end

    it "generates match line for parallel view" do
      output = diff_match_line old_pos, new_pos, text: text, view: :parallel

      expect(output).to be_html_safe
      expect(output).to have_css "td:nth-child(1):not(.js-unfold-bottom).diff-line-num.unfold.js-unfold.old_line[data-linenumber='#{old_pos}']", text: '...'
      expect(output).to have_css 'td:nth-child(2).line_content.match.parallel', text: text
      expect(output).to have_css "td:nth-child(3):not(.js-unfold-bottom).diff-line-num.unfold.js-unfold.new_line[data-linenumber='#{new_pos}']", text: '...'
      expect(output).to have_css 'td:nth-child(4).line_content.match.parallel', text: text
    end

    it "allows to generate only left match line for parallel view" do
      output = diff_match_line old_pos, nil, text: text, view: :parallel

      expect(output).to be_html_safe
      expect(output).to have_css "td:nth-child(1):not(.js-unfold-bottom).diff-line-num.unfold.js-unfold.old_line[data-linenumber='#{old_pos}']", text: '...'
      expect(output).to have_css 'td:nth-child(2).line_content.match.parallel', text: text
      expect(output).not_to have_css 'td:nth-child(3)'
    end

    it "allows to generate only right match line for parallel view" do
      output = diff_match_line nil, new_pos, text: text, view: :parallel

      expect(output).to be_html_safe
      expect(output).to have_css "td:nth-child(1):not(.js-unfold-bottom).diff-line-num.unfold.js-unfold.new_line[data-linenumber='#{new_pos}']", text: '...'
      expect(output).to have_css 'td:nth-child(2).line_content.match.parallel', text: text
      expect(output).not_to have_css 'td:nth-child(3)'
    end
  end

  context 'viewer related' do
    let(:viewer) { diff_file.simple_viewer }

    before do
      assign(:project, project)
    end

    describe '#diff_render_error_reason' do
      context 'for error :too_large' do
        before do
          expect(viewer).to receive(:render_error).and_return(:too_large)
        end

        it 'returns an error message' do
          expect(helper.diff_render_error_reason(viewer)).to eq('it is too large')
        end
      end

      context 'for error :server_side_but_stored_externally' do
        before do
          expect(viewer).to receive(:render_error).and_return(:server_side_but_stored_externally)
          expect(diff_file).to receive(:external_storage).and_return(:lfs)
        end

        it 'returns an error message' do
          expect(helper.diff_render_error_reason(viewer)).to eq('it is stored in LFS')
        end
      end
    end

    describe '#diff_render_error_options' do
      it 'includes a "view the blob" link' do
        expect(helper.diff_render_error_options(viewer)).to include(/view the blob/)
      end
    end
  end

  context '#diff_file_path_text' do
    it 'returns full path by default' do
      expect(diff_file_path_text(diff_file)).to eq(diff_file.new_path)
    end

    it 'returns truncated path' do
      expect(diff_file_path_text(diff_file, max: 10)).to eq("...open.rb")
    end
  end
end
