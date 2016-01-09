require 'spec_helper'

describe DiffHelper do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diffs) { commit.diffs }
  let(:diff) { diffs.first }
  let(:diff_refs) { [commit.parent.id, commit.id] }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs, repository) }

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
      expect(safe_diff_files(diffs, diff_refs, repository).length).to eq(2)
    end

    it 'should return only the first file if the diff line count in the 2nd file takes the total beyond safe limits' do
      allow(diffs[1].diff).to receive(:lines).and_return([""] * 4999) #simulate 4999 lines
      expect(safe_diff_files(diffs, diff_refs, repository).length).to eq(1)
    end

    it 'should return all files from a commit that is beyond safe limit for numbers of lines if force diff is true' do
      allow(controller).to receive(:params) { { force_show_diff: true } }
      allow(diffs[1].diff).to receive(:lines).and_return([""] * 4999) #simulate 4999 lines
      expect(safe_diff_files(diffs, diff_refs, repository).length).to eq(2)
    end

    it 'should return only the first file if the diff line count in the 2nd file takes the total beyond hard limits' do
      allow(controller).to receive(:params) { { force_show_diff: true } }
      allow(diffs[1].diff).to receive(:lines).and_return([""] * 49999) #simulate 49999 lines
      expect(safe_diff_files(diffs, diff_refs, repository).length).to eq(1)
    end

    it 'should return only a safe number of file diffs if a commit touches more files than the safe limits' do
      large_diffs = diffs * 100 #simulate 200 diffs
      expect(safe_diff_files(large_diffs, diff_refs, repository).length).to eq(100)
    end

    it 'should return all file diffs if a commit touches more files than the safe limits but force diff is true' do
      allow(controller).to receive(:params) { { force_show_diff: true } }
      large_diffs = diffs * 100 #simulate 200 diffs
      expect(safe_diff_files(large_diffs, diff_refs, repository).length).to eq(200)
    end

    it 'should return a limited file diffs if a commit touches more files than the hard limits and force diff is true' do
      allow(controller).to receive(:params) { { force_show_diff: true } }
      very_large_diffs = diffs * 1000 #simulate 2000 diffs
      expect(safe_diff_files(very_large_diffs, diff_refs, repository).length).to eq(1000)
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
    YAML.load_file("#{Rails.root}/spec/fixtures/parallel_diff_result.yml")
  end
end
