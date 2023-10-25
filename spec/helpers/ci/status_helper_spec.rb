# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::StatusHelper do
  include IconsHelper

  let(:success_commit) { double("Ci::Pipeline", status: 'success') }
  let(:failed_commit) { double("Ci::Pipeline", status: 'failed') }

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

  describe "#render_ci_icon" do
    subject { helper.render_ci_icon("success") }

    it "has 'Pipeline' as the status type in the title" do
      is_expected.to include("title=\"Pipeline: passed\"")
    end

    it "has the success status icon" do
      is_expected.to include("ci-status-icon-success")
    end

    context "when pipeline has commit path" do
      subject { helper.render_ci_icon("success", "/commit-path") }

      it "links to commit" do
        is_expected.to include("href=\"/commit-path\"")
      end

      it "has 'Pipeline' as the status type in the title" do
        is_expected.to include("title=\"Pipeline: passed\"")
      end

      it "has the correct status icon" do
        is_expected.to include("ci-status-icon-success")
      end
    end

    context "when tooltip_placement is provided" do
      subject { helper.render_ci_icon("success", tooltip_placement: "right") }

      it "has the provided tooltip placement" do
        is_expected.to include("data-placement=\"right\"")
      end
    end

    context "when container is provided" do
      subject { helper.render_ci_icon("success", container: "my-container") }

      it "has the provided container in data" do
        is_expected.to include("data-container=\"my-container\"")
      end
    end

    context "when status is success-with-warnings" do
      subject { helper.render_ci_icon("success-with-warnings") }

      it "renders warning variant of gl-badge" do
        is_expected.to include('gl-badge badge badge-pill badge-warning')
      end
    end

    context "when status is manual" do
      subject { helper.render_ci_icon("manual") }

      it "renders neutral variant of gl-badge" do
        is_expected.to include('gl-badge badge badge-pill badge-neutral')
      end
    end
  end

  describe '#badge_variant' do
    using RSpec::Parameterized::TableSyntax

    where(:status, :expected_badge_variant_class) do
      'success'               | 'badge-success'
      'success-with-warnings' | 'badge-warning'
      'pending'               | 'badge-warning'
      'failed'                | 'badge-danger'
      'running'               | 'badge-info'
      'canceled'              | 'badge-neutral'
      'manual'                | 'badge-neutral'
      'other-status'          | 'badge-muted'
    end

    with_them do
      subject { helper.render_ci_icon(status) }

      it 'uses the correct badge variant classes for gl-badge' do
        is_expected.to include("gl-badge badge badge-pill #{expected_badge_variant_class}")
      end
    end
  end

  describe '#ci_icon_for_status' do
    using RSpec::Parameterized::TableSyntax

    where(:status, :icon_variant) do
      'success'               | 'status_success'
      'success-with-warnings' | 'status_warning'
      'preparing'             | 'status_preparing'
      'pending'               | 'status_pending'
      'waiting-for-resource'  | 'status_pending'
      'failed'                | 'status_failed'
      'running'               | 'status_running'
      'canceled'              | 'status_canceled'
      'created'               | 'status_created'
      'scheduled'             | 'status_scheduled'
      'play'                  | 'play'
      'skipped'               | 'status_skipped'
      'manual'                | 'status_manual'
    end

    with_them do
      subject { helper.render_ci_icon(status).to_s }

      it 'uses the correct icon variant for status' do
        is_expected.to include("ci-status-icon-#{status}")
        is_expected.to include(icon_variant)
      end
    end
  end
end
