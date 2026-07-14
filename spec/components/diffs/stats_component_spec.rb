# frozen_string_literal: true

require "spec_helper"

RSpec.describe Diffs::StatsComponent, type: :component do
  include RepoHelpers

  subject(:component) do
    described_class.new(diff_files: diff_files)
  end

  let_it_be(:project, freeze: false) { create(:project, :repository) }
  let_it_be(:repository, freeze: false) { project.repository }
  let_it_be(:commit, freeze: false) { project.commit(sample_commit.id) }
  let_it_be(:diffs, freeze: false) { commit.raw_diffs }
  let_it_be(:diff, freeze: false) { diffs.first }
  let_it_be(:diff_refs, freeze: false) { commit.diff_refs }
  let_it_be(:diff_file, freeze: false) { Gitlab::Diff::File.new(diff, diff_refs: diff_refs, repository: repository) }

  let(:diff_files) { [diff_file] }

  describe "rendered component" do
    subject { page }

    let(:element) { page.find(".js-diff-stats-dropdown") }

    before do
      render_inline component
    end

    it { is_expected.to have_selector(".js-diff-stats-dropdown") }

    it "renders the data attributes" do
      expect(element["data-changed"]).to eq("1")
      expect(element["data-added"]).to eq("10")
      expect(element["data-deleted"]).to eq("3")

      expect(Gitlab::Json.parse(element["data-files"])).to eq([{
        "href" => "##{Digest::SHA1.hexdigest(diff_file.file_path)}",
        "title" => diff_file.new_path,
        "name" => diff_file.file_path,
        "path" => diff_file.file_path,
        "icon" => "file-modified",
        "iconColor" => "",
        "added" => diff_file.added_lines,
        "removed" => diff_file.removed_lines
      }])
    end
  end

  describe "#diff_file_path_text" do
    it "returns full path by default" do
      expect(subject.diff_file_path_text(diff_file)).to eq(diff_file.new_path)
    end

    it "returns truncated path" do
      expect(subject.diff_file_path_text(diff_file, max: 10)).to eq("...open.rb")
    end

    it "returns the path if max is oddly small" do
      expect(subject.diff_file_path_text(diff_file, max: 3)).to eq(diff_file.new_path)
    end

    it "returns the path if max is oddly large" do
      expect(subject.diff_file_path_text(diff_file, max: 100)).to eq(diff_file.new_path)
    end
  end
end
