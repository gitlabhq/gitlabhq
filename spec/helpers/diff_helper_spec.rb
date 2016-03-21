require 'spec_helper'

describe DiffHelper do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diffs) { commit.diffs }
  let(:diff) { diffs.first }
  let(:diff_refs) { [commit.parent, commit] }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs) }

  describe 'diff_hard_limit_enabled?' do
    it 'should return true if param is provided' do
      allow(controller).to receive(:params) { { force_show_diff: true } }
      expect(diff_hard_limit_enabled?).to be_truthy
    end

    it 'should return false if param is not provided' do
      expect(diff_hard_limit_enabled?).to be_falsey
    end
  end

  describe 'diff_options' do
    it 'should return hard limit for a diff if force diff is true' do
      allow(controller).to receive(:params) { { force_show_diff: true } }
      expect(diff_options).to include(Commit.max_diff_options)
    end

    it 'should return safe limit for a diff if force diff is false' do
      expect(diff_options).not_to include(:max_lines, :max_files)
    end
  end

  describe 'unfold_bottom_class' do
    it 'should return empty string when bottom line shouldnt be unfolded' do
      expect(unfold_bottom_class(false)).to eq('')
    end

    it 'should return js class when bottom lines should be unfolded' do
      expect(unfold_bottom_class(true)).to eq('js-unfold-bottom')
    end
  end

  describe 'unfold_class' do
    it 'returns empty on false' do
      expect(unfold_class(false)).to eq('')
    end

    it 'returns a class on true' do
      expect(unfold_class(true)).to eq('unfold js-unfold')
    end
  end

  describe '#diff_line_content' do
    it 'should return non breaking space when line is empty' do
      expect(diff_line_content(nil)).to eq(' &nbsp;')
    end

    it 'should return the line itself' do
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

      expect(marked_old_line).to eq("abc <span class='idiff left right'>&#39;def&#39;</span>")
      expect(marked_old_line).to be_html_safe
      expect(marked_new_line).to eq("abc <span class='idiff left right'>&quot;def&quot;</span>")
      expect(marked_new_line).to be_html_safe
    end
  end
end
