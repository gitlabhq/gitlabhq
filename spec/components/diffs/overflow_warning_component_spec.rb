# frozen_string_literal: true

require "spec_helper"

RSpec.describe Diffs::OverflowWarningComponent, type: :component, feature_category: :source_code_management do
  include RepoHelpers

  subject(:component) do
    described_class.new(
      diffs: diffs,
      diff_files: diff_files,
      project: project,
      commit: commit,
      merge_request: merge_request
    )
  end

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository }
  let_it_be(:commit) { project.commit(sample_commit.id) }
  let_it_be(:diffs) { commit.raw_diffs }
  let_it_be(:diff) { diffs.first }
  let_it_be(:diff_refs) { commit.diff_refs }
  let_it_be(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs: diff_refs, repository: repository) }
  let_it_be(:diff_files) { [diff_file] }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let(:expected_button_classes) do
    "gl-button btn btn-md btn-default"
  end

  def parse_link(html)
    Nokogiri::HTML5.fragment(html).at_css("a")
  end

  describe "rendered component" do
    subject { rendered_content }

    context "on a commit page" do
      before do
        with_controller_class Projects::CommitController do
          render_inline component
        end
      end

      it { is_expected.to include(component.message) }

      it "links to the diff" do
        link = parse_link(component.diff_link)

        expect(link.text.strip).to eq(_("Plain diff"))
        expect(link["href"]).to eq(project_commit_path(project, commit, format: :diff))
        expect(link["class"]).to include(expected_button_classes)

        is_expected.to include(component.diff_link)
      end

      it "links to the patch" do
        link = parse_link(component.patch_link)

        expect(link.text.strip).to eq(_("Email patch"))
        expect(link["href"]).to eq(project_commit_path(project, commit, format: :patch))
        expect(link["class"]).to include(expected_button_classes)

        is_expected.to include(component.patch_link)
      end
    end

    context "on a merge request page and the merge request is persisted" do
      before do
        with_controller_class Projects::MergeRequests::DiffsController do
          render_inline component
        end
      end

      it { is_expected.to include(component.message) }

      it "links to the diff" do
        link = parse_link(component.diff_link)

        expect(link.text.strip).to eq(_("Plain diff"))
        expect(link["href"]).to eq(merge_request_path(merge_request, format: :diff))
        expect(link["class"]).to include(expected_button_classes)

        is_expected.to include(component.diff_link)
      end

      it "links to the patch" do
        link = parse_link(component.patch_link)

        expect(link.text.strip).to eq(_("Email patch"))
        expect(link["href"]).to eq(merge_request_path(merge_request, format: :patch))
        expect(link["class"]).to include(expected_button_classes)

        is_expected.to include(component.patch_link)
      end
    end

    # Compare revisions or Merge Request create page
    context "both conditions fail" do
      before do
        allow(component).to receive(:commit?).and_return(false)
        allow(component).to receive(:merge_request?).and_return(false)
        render_inline component
      end

      it { is_expected.to include(component.message) }
      it { is_expected.not_to include(expected_button_classes) }
      it { is_expected.not_to include("Plain diff") }
      it { is_expected.not_to include("Email patch") }
    end
  end

  describe "#message" do
    subject { component.message }

    it { is_expected.to be_a(String) }

    it "is HTML-safe" do
      expect(subject.html_safe?).to be_truthy
    end
  end

  describe "#diff_link" do
    subject { component.diff_link }

    before do
      render_inline component
      allow(component).to receive(:link_button_to).and_return("foo")
    end

    it "is a string when on a commit page" do
      allow(component).to receive(:commit?).and_return(true)

      is_expected.to eq("foo")
    end

    it "is a string when on a merge request page" do
      allow(component).to receive(:commit?).and_return(false)
      allow(component).to receive(:merge_request?).and_return(true)

      is_expected.to eq("foo")
    end

    it "is nil in other situations" do
      allow(component).to receive(:commit?).and_return(false)
      allow(component).to receive(:merge_request?).and_return(false)

      is_expected.to be_nil
    end
  end

  describe "#patch_link" do
    subject { component.patch_link }

    before do
      render_inline component
      allow(component).to receive(:link_button_to).and_return("foo")
    end

    it "is a string when on a commit page" do
      allow(component).to receive(:commit?).and_return(true)

      is_expected.to eq("foo")
    end

    it "is a string when on a merge request page" do
      allow(component).to receive(:commit?).and_return(false)
      allow(component).to receive(:merge_request?).and_return(true)

      is_expected.to eq("foo")
    end

    it "is nil in other situations" do
      allow(component).to receive(:commit?).and_return(false)
      allow(component).to receive(:merge_request?).and_return(false)

      is_expected.to be_nil
    end
  end

  describe '#message_text' do
    subject { component.message_text }

    context "when on a commit page" do
      before do
        allow(component).to receive(:commit?).and_return(true)
        render_inline component
      end

      it "contains base and download message" do
        expect(subject).to include(_("For a faster browsing experience, only %{strong_open}%{display_size} of " \
          "%{real_size}%{strong_close} files are shown."))
        expect(subject).to include(_("Download one of the files below to see all changes."))
      end
    end

    context "when on a merge request page" do
      before do
        allow(component).to receive(:merge_request?).and_return(true)
        render_inline component
      end

      it "contains base and download message" do
        expect(subject).to include(_("For a faster browsing experience, only %{strong_open}%{display_size} of " \
          "%{real_size}%{strong_close} files are shown."))
        expect(subject).to include(_("Download one of the files below to see all changes."))
      end
    end

    context "when not on a commit or merge request page" do
      before do
        allow(component).to receive(:commit?).and_return(false)
        allow(component).to receive(:merge_request?).and_return(false)
        render_inline component
      end

      it "contains base message only" do
        expect(subject).to include(_("For a faster browsing experience, only %{strong_open}%{display_size} of " \
          "%{real_size}%{strong_close} files are shown."))
        expect(subject).not_to include(_("Download one of the files below to see all changes."))
      end
    end
  end
end
