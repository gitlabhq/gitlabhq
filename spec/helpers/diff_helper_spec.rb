# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffHelper do
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

  describe "#diff_link_number" do
    using RSpec::Parameterized::TableSyntax

    let(:line) do
      double(:line, type: line_type)
    end

    # This helper is used to generate the line numbers on the
    # diff lines. It essentially just returns a blank string
    # on the old/new lines. The following table tests all the
    # possible permutations for clarity.

    where(:line_type, :match, :line_number, :expected_return_value) do
      "new"           | "new" | 1  | " "
      "new"           | "old" | 2  | 2
      "old"           | "new" | 3  | 3
      "old"           | "old" | 4  | " "
      "new-nonewline" | "new" | 5  | 5
      "new-nonewline" | "old" | 6  | 6
      "old-nonewline" | "new" | 7  | 7
      "old-nonewline" | "old" | 8  | 8
      "match"         | "new" | 9  | 9
      "match"         | "old" | 10 | 10
    end

    with_them do
      it "returns the expected value" do
        expect(helper.diff_link_number(line.type, match, line_number)).to eq(expected_return_value)
      end
    end
  end

  describe "#mark_inline_diffs" do
    let(:old_line) { %{abc 'def'} }
    let(:new_line) { %{abc "def"} }

    it "returns strings with marked inline diffs" do
      marked_old_line, marked_new_line = mark_inline_diffs(old_line, new_line)

      expect(marked_old_line).to eq(%q{abc <span class="idiff left deletion">&#39;</span>def<span class="idiff right deletion">&#39;</span>})
      expect(marked_old_line).to be_html_safe
      expect(marked_new_line).to eq(%q{abc <span class="idiff left addition">&quot;</span>def<span class="idiff right addition">&quot;</span>})
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

  describe '#render_overflow_warning?' do
    using RSpec::Parameterized::TableSyntax

    let(:diffs_collection) { instance_double(Gitlab::Diff::FileCollection::MergeRequestDiff, raw_diff_files: diff_files, overflow?: false) }
    let(:diff_files) { Gitlab::Git::DiffCollection.new(files) }
    let(:safe_file) { { too_large: false, diff: '' } }
    let(:large_file) { { too_large: true, diff: '' } }
    let(:files) { [safe_file, safe_file] }

    context 'when no limits are hit' do
      before do
        allow(diff_files).to receive(:overflow_max_bytes?).and_return(false)
        allow(diff_files).to receive(:overflow_max_files?).and_return(false)
        allow(diff_files).to receive(:overflow_max_lines?).and_return(false)
        allow(diff_files).to receive(:collapsed_safe_bytes?).and_return(false)
        allow(diff_files).to receive(:collapsed_safe_files?).and_return(false)
        allow(diff_files).to receive(:collapsed_safe_lines?).and_return(false)
      end

      it 'returns false and does not log any overflow events' do
        expect(Gitlab::Metrics).not_to receive(:add_event).with(:diffs_overflow_collection_limits)
        expect(Gitlab::Metrics).not_to receive(:add_event).with(:diffs_overflow_single_file_limits)
        expect(Gitlab::Metrics).not_to receive(:add_event).with(:diffs_overflow_max_bytes_limits)
        expect(Gitlab::Metrics).not_to receive(:add_event).with(:diffs_overflow_max_files_limits)
        expect(Gitlab::Metrics).not_to receive(:add_event).with(:diffs_overflow_max_lines_limits)
        expect(Gitlab::Metrics).not_to receive(:add_event).with(:diffs_overflow_collapsed_bytes_limits)
        expect(Gitlab::Metrics).not_to receive(:add_event).with(:diffs_overflow_collapsed_files_limits)
        expect(Gitlab::Metrics).not_to receive(:add_event).with(:diffs_overflow_collapsed_lines_limits)

        expect(render_overflow_warning?(diffs_collection)).to be false
      end
    end

    where(:overflow_method, :event_name) do
      :overflow_max_bytes?      | :diffs_overflow_max_bytes_limits
      :overflow_max_files?      | :diffs_overflow_max_files_limits
      :overflow_max_lines?      | :diffs_overflow_max_lines_limits
      :collapsed_safe_bytes?    | :diffs_overflow_collapsed_bytes_limits
      :collapsed_safe_files?    | :diffs_overflow_collapsed_files_limits
      :collapsed_safe_lines?    | :diffs_overflow_collapsed_lines_limits
    end

    with_them do
      it 'returns false and only logs the correct collection overflow event' do
        allow(diff_files).to receive(overflow_method).and_return(true)
        expect(Gitlab::Metrics).to receive(:add_event).with(event_name).once
        expect(render_overflow_warning?(diffs_collection)).to be false
      end
    end

    context 'when the file collection has an overflow' do
      before do
        allow(diffs_collection).to receive(:overflow?).and_return(true)
      end

      it 'returns true and only logs all the correct collection overflow event' do
        expect(Gitlab::Metrics).to receive(:add_event).with(:diffs_overflow_collection_limits).once

        expect(render_overflow_warning?(diffs_collection)).to be true
      end
    end

    context 'when two individual files are too big' do
      let(:files) { [safe_file, large_file, large_file] }

      it 'returns false and only logs single file overflow events' do
        expect(Gitlab::Metrics).to receive(:add_event).with(:diffs_overflow_single_file_limits).exactly(:once)
        expect(Gitlab::Metrics).not_to receive(:add_event).with(:diffs_overflow_collection_limits)

        expect(render_overflow_warning?(diffs_collection)).to be false
      end
    end
  end

  describe '#diff_file_html_data' do
    let(:project) { build(:project) }
    let(:path) { 'path/to/file' }
    let(:sha) { '1234567890' }

    subject do
      helper.diff_file_html_data(project, path, sha)
    end

    it 'returns data for project files' do
      expect(subject).to include(blob_diff_path: helper.project_blob_diff_path(project, "#{sha}/#{path}"))
    end
  end

  describe '#diff_file_path_text' do
    it 'returns full path by default' do
      expect(diff_file_path_text(diff_file)).to eq(diff_file.new_path)
    end

    it 'returns truncated path' do
      expect(diff_file_path_text(diff_file, max: 10)).to eq("...open.rb")
    end
  end

  describe "#collapsed_diff_url" do
    let(:params) do
      {
        controller: "projects/commit",
        action: "show",
        namespace_id: "foo",
        project_id: "bar",
        id: commit.sha
      }
    end

    subject { helper.collapsed_diff_url(diff_file) }

    it "returns a valid URL" do
      allow(helper).to receive(:safe_params).and_return(params)

      expect(subject).to match(%r{foo/bar/-/commit/#{commit.sha}/diff_for_path})
    end
  end

  describe "#render_fork_suggestion" do
    subject { helper.render_fork_suggestion }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    context "user signed in" do
      let(:current_user) { build(:user) }

      it "renders the partial" do
        expect(helper).to receive(:render).with(partial: "projects/fork_suggestion").exactly(:once)

        5.times { subject }
      end
    end

    context "guest" do
      let(:current_user) { nil }

      it { is_expected.to be_nil }
    end
  end
end
