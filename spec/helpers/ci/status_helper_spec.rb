# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::StatusHelper do
  include IconsHelper

  let(:success_commit) { double("Ci::Pipeline", status: 'success') }
  let(:failed_commit) { double("Ci::Pipeline", status: 'failed') }

  describe '#ci_icon_for_status' do
    it 'renders to correct svg on success' do
      expect(helper.ci_icon_for_status('success').to_s)
        .to include 'status_success'
    end

    it 'renders the correct svg on failure' do
      expect(helper.ci_icon_for_status('failed').to_s)
        .to include 'status_failed'
    end
  end

  describe '#ci_text_for_status' do
    context 'when status is manual' do
      it 'changes the status to blocked' do
        expect(helper.ci_text_for_status('manual'))
          .to eq 'blocked'
      end
    end

    context 'when status is success' do
      it 'changes the status to passed' do
        expect(helper.ci_text_for_status('success'))
          .to eq 'passed'
      end
    end

    context 'when status is something else' do
      it 'returns status unchanged' do
        expect(helper.ci_text_for_status('some-status'))
          .to eq 'some-status'
      end
    end
  end

  describe "#pipeline_status_cache_key" do
    it "builds a cache key for pipeline status" do
      pipeline_status = Gitlab::Cache::Ci::ProjectPipelineStatus.new(
        build_stubbed(:project),
        pipeline_info: {
          sha: "123abc",
          status: "success"
        }
      )
      expect(helper.pipeline_status_cache_key(pipeline_status)).to eq("pipeline-status/123abc-success")
    end
  end

  describe "#render_status_with_link" do
    subject { helper.render_status_with_link("success") }

    it "renders a passed status icon" do
      is_expected.to include("<span class=\"ci-status-link ci-status-icon-success d-inline-flex")
    end

    it "has 'Pipeline' as the status type in the title" do
      is_expected.to include("title=\"Pipeline: passed\"")
    end

    it "has the success status icon" do
      is_expected.to include("ci-status-icon-success")
    end

    context "when pipeline has commit path" do
      subject { helper.render_status_with_link("success", "/commit-path") }

      it "links to commit" do
        is_expected.to include("href=\"/commit-path\"")
      end

      it "does not contain a span element" do
        is_expected.not_to include("<span")
      end

      it "has 'Pipeline' as the status type in the title" do
        is_expected.to include("title=\"Pipeline: passed\"")
      end

      it "has the correct status icon" do
        is_expected.to include("ci-status-icon-success")
      end
    end

    context "when different type than pipeline is provided" do
      subject { helper.render_status_with_link("success", type: "commit") }

      it "has the provided type in the title" do
        is_expected.to include("title=\"Commit: passed\"")
      end
    end

    context "when tooltip_placement is provided" do
      subject { helper.render_status_with_link("success", tooltip_placement: "right") }

      it "has the provided tooltip placement" do
        is_expected.to include("data-placement=\"right\"")
      end
    end

    context "when additional CSS classes are provided" do
      subject { helper.render_status_with_link("success", cssclass: "extra-class") }

      it "has appended extra class to icon classes" do
        is_expected.to include("class=\"ci-status-link ci-status-icon-success d-inline-flex extra-class\"")
      end
    end

    context "when container is provided" do
      subject { helper.render_status_with_link("success", container: "my-container") }

      it "has the provided container in data" do
        is_expected.to include("data-container=\"my-container\"")
      end
    end

    context "when icon_size is provided" do
      subject { helper.render_status_with_link("success", icon_size: 24) }

      it "has the svg class to change size" do
        is_expected.to include("<svg class=\"s24\"")
      end
    end
  end
end
