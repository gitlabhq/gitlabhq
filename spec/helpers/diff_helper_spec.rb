require 'spec_helper'

describe DiffHelper do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:commit) { project.repository.commit(sample_commit.id) }
  let(:diff) { commit.diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff) }

  describe 'diff_hard_limit_enabled?' do
    it 'should return true if param is provided' do
      controller.stub(:params).and_return { { :force_show_diff => true } }
      diff_hard_limit_enabled?.should be_true
    end

    it 'should return false if param is not provided' do
      diff_hard_limit_enabled?.should be_false
    end
  end

  describe 'allowed_diff_size' do
    it 'should return hard limit for a diff if force diff is true' do
      controller.stub(:params).and_return { { :force_show_diff => true } }
      allowed_diff_size.should eq(1000)
    end

    it 'should return safe limit for a diff if force diff is false' do
      allowed_diff_size.should eq(100)
    end
  end

  describe 'parallel_diff' do
    it 'should return an array of arrays containing the parsed diff' do
      parallel_diff(diff_file, 0).should match_array(parallel_diff_result_array)
    end
  end

  describe 'generate_line_code' do
    it 'should generate correct line code' do
      generate_line_code(diff_file.file_path, diff_file.diff_lines.first).should == '2f6fcd96b88b36ce98c38da085c795a27d92a3dd_6_6'
    end
  end

  describe 'unfold_bottom_class' do
    it 'should return empty string when bottom line shouldnt be unfolded' do
      unfold_bottom_class(false).should == ''
    end

    it 'should return js class when bottom lines should be unfolded' do
      unfold_bottom_class(true).should == 'js-unfold-bottom'
    end
  end

  describe 'diff_line_content' do

    it 'should return non breaking space when line is empty' do
      diff_line_content(nil).should eq(" &nbsp;")
    end

    it 'should return the line itself' do
      diff_line_content(diff_file.diff_lines.first.text).should eq("@@ -6,12 +6,18 @@ module Popen")
      diff_line_content(diff_file.diff_lines.first.type).should eq("match")
      diff_line_content(diff_file.diff_lines.first.new_pos).should eq(6)
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
