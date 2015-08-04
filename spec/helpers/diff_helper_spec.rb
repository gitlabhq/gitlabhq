require 'spec_helper'

describe DiffHelper do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diffs) { commit.diffs }
  let(:diff) { diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff) }

  describe 'diff_hard_limit_enabled?' do
    it 'should return true if param is provided' do
      allow(controller).to receive(:params) { { force_show_diff: true } }
      expect(diff_hard_limit_enabled?).to be_truthy
    end

    it 'should return false if param is not provided' do
      expect(diff_hard_limit_enabled?).to be_falsey
    end
  end

  describe 'allowed_diff_size' do
    it 'should return hard limit for a diff if force diff is true' do
      allow(controller).to receive(:params) { { force_show_diff: true } }
      expect(allowed_diff_size).to eq(1000)
    end

    it 'should return safe limit for a diff if force diff is false' do
      expect(allowed_diff_size).to eq(100)
    end
  end

  describe 'allowed_diff_lines' do
    it 'should return hard limit for number of lines in a diff if force diff is true' do
      allow(controller).to receive(:params) { { force_show_diff: true } }
      expect(allowed_diff_lines).to eq(50000)
    end

    it 'should return safe limit for numbers of lines a diff if force diff is false' do
      expect(allowed_diff_lines).to eq(5000)
    end
  end

  describe 'safe_diff_files' do
    it 'should return all files from a commit that is smaller than safe limits' do
      expect(safe_diff_files(diffs).length).to eq(2)
    end

    it 'should return only the first file if the diff line count in the 2nd file takes the total beyond safe limits' do
      allow(diffs[1].diff).to receive(:lines).and_return([""] * 4999) #simulate 4999 lines
      expect(safe_diff_files(diffs).length).to eq(1)
    end

    it 'should return all files from a commit that is beyond safe limit for numbers of lines if force diff is true' do
      allow(controller).to receive(:params) { { force_show_diff: true } }
      allow(diffs[1].diff).to receive(:lines).and_return([""] * 4999) #simulate 4999 lines
      expect(safe_diff_files(diffs).length).to eq(2)
    end

    it 'should return only the first file if the diff line count in the 2nd file takes the total beyond hard limits' do
      allow(controller).to receive(:params) { { force_show_diff: true } }
      allow(diffs[1].diff).to receive(:lines).and_return([""] * 49999) #simulate 49999 lines
      expect(safe_diff_files(diffs).length).to eq(1)
    end

    it 'should return only a safe number of file diffs if a commit touches more files than the safe limits' do
      large_diffs = diffs * 100 #simulate 200 diffs
      expect(safe_diff_files(large_diffs).length).to eq(100)
    end

    it 'should return all file diffs if a commit touches more files than the safe limits but force diff is true' do
      allow(controller).to receive(:params) { { force_show_diff: true } }
      large_diffs = diffs * 100 #simulate 200 diffs
      expect(safe_diff_files(large_diffs).length).to eq(200)
    end

    it 'should return a limited file diffs if a commit touches more files than the hard limits and force diff is true' do
      allow(controller).to receive(:params) { { force_show_diff: true } }
      very_large_diffs = diffs * 1000 #simulate 2000 diffs
      expect(safe_diff_files(very_large_diffs).length).to eq(1000)
    end
  end

  describe 'parallel_diff' do
    it 'should return an array of arrays containing the parsed diff' do
      expect(parallel_diff(diff_file, 0)).
        to match_array(parallel_diff_result_array)
    end
  end

  describe 'generate_line_code' do
    it 'should generate correct line code' do
      expect(generate_line_code(diff_file.file_path, diff_file.diff_lines.first)).
        to eq('2f6fcd96b88b36ce98c38da085c795a27d92a3dd_6_6')
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

  describe 'diff_line_content' do

    it 'should return non breaking space when line is empty' do
      expect(diff_line_content(nil)).to eq(' &nbsp;')
    end

    it 'should return the line itself' do
      expect(diff_line_content(diff_file.diff_lines.first.text)).
        to eq('@@ -6,12 +6,18 @@ module Popen')
      expect(diff_line_content(diff_file.diff_lines.first.type)).to eq('match')
      expect(diff_line_content(diff_file.diff_lines.first.new_pos)).to eq(6)
    end
  end

  def parallel_diff_result_array
    [
      ["match", 6, "@@ -6,12 +6,18 @@ module Popen", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_6_6", "match", 6, "@@ -6,12 +6,18 @@ module Popen", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_6_6"],
      [nil, 6, " ", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_6_6", nil, 6, " ", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_6_6"], [nil, 7, "   def popen(cmd, path=nil)", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_7_7", nil, 7, "   def popen(cmd, path=nil)", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_7_7"],
      [nil, 8, "     unless cmd.is_a?(Array)", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_8_8", nil, 8, "     unless cmd.is_a?(Array)", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_8_8"],
      ["old", 9, "-      raise <span class='idiff'></span>&quot;System commands must be given as an array of strings&quot;", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_9_9", "new", 9, "+      raise <span class='idiff'>RuntimeError, </span>&quot;System commands must be given as an array of strings&quot;", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_9"],
      [nil, 10, "     end", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_10", nil, 10, "     end", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_10"],
      [nil, 11, " ", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_11_11", nil, 11, " ", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_11_11"],
      [nil, 12, "     path ||= Dir.pwd", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_12_12", nil, 12, "     path ||= Dir.pwd", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_12_12"],
      ["old", 13, "-    vars = { &quot;PWD&quot; =&gt; path }", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_13_13", "old", nil, "&nbsp;", nil],
      ["old", 14, "-    options = { chdir: path }", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_14_13", "new", 13, "+", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_13"],
      [nil, nil, "&nbsp;", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_14", "new", 14, "+    vars = {", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_14"],
      [nil, nil, "&nbsp;", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_15", "new", 15, "+      &quot;PWD&quot; =&gt; path", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_15"],
      [nil, nil, "&nbsp;", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_16", "new", 16, "+    }", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_16"],
      [nil, nil, "&nbsp;", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_17", "new", 17, "+", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_17"],
      [nil, nil, "&nbsp;", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_18", "new", 18, "+    options = {", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_18"],
      [nil, nil, "&nbsp;", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_19", "new", 19, "+      chdir: path", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_19"],
      [nil, nil, "&nbsp;", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_20", "new", 20, "+    }", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_20"],
      [nil, 15, " ", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_21", nil, 21, " ", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_21"],
      [nil, 16, "     unless File.directory?(path)", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_16_22", nil, 22, "     unless File.directory?(path)", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_16_22"],
      [nil, 17, "       FileUtils.mkdir_p(path)", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_17_23", nil, 23, "       FileUtils.mkdir_p(path)", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_17_23"],
      ["match", 19, "@@ -19,6 +25,7 @@ module Popen", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_19_25", "match", 25, "@@ -19,6 +25,7 @@ module Popen", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_19_25"],
      [nil, 19, " ", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_19_25", nil, 25, " ", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_19_25"],
      [nil, 20, "     @cmd_output = &quot;&quot;", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_20_26", nil, 26, "     @cmd_output = &quot;&quot;", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_20_26"],
      [nil, 21, "     @cmd_status = 0", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_21_27", nil, 27, "     @cmd_status = 0", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_21_27"],
      [nil, nil, "&nbsp;", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_22_28", "new", 28, "+", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_22_28"],
      [nil, 22, "     Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_22_29", nil, 29, "     Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_22_29"],
      [nil, 23, "       @cmd_output &lt;&lt; stdout.read", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_23_30", nil, 30, "       @cmd_output &lt;&lt; stdout.read", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_23_30"],
      [nil, 24, "       @cmd_output &lt;&lt; stderr.read", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_24_31", nil, 31, "       @cmd_output &lt;&lt; stderr.read", "2f6fcd96b88b36ce98c38da085c795a27d92a3dd_24_31"]
    ]
  end
end
