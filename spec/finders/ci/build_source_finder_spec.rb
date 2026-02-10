# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildSourceFinder, feature_category: :continuous_integration do
  let_it_be(:pipeline) { create(:ci_pipeline, source: "push") }

  let_it_be(:build_non_relevant) { create(:ci_build, pipeline: pipeline, name: "unique-name") }
  let_it_be(:old_build) { create(:ci_build, pipeline: pipeline, name: "build1") }
  let_it_be(:old_middle_build) { create(:ci_build, pipeline: pipeline, name: "build2") }
  let_it_be(:middle_build) { create(:ci_build, pipeline: pipeline, name: "build3") }
  let_it_be(:middle_new_build) { create(:ci_build, pipeline: pipeline, name: "build4") }
  let_it_be(:new_build) { create(:ci_build, pipeline: pipeline, name: "build5") }

  let_it_be(:old_build_source) { create(:ci_build_source, job: old_build, source: :scan_execution_policy) }
  let_it_be(:old_middle_build_source) { create(:ci_build_source, job: old_middle_build, source: :trigger) }
  let_it_be(:middle_build_source) { create(:ci_build_source, job: middle_build, source: :scan_execution_policy) }
  let_it_be(:middle_new_build_source) { create(:ci_build_source, job: middle_new_build, source: :push) }
  let_it_be(:new_build_source) { create(:ci_build_source, job: new_build, source: :scan_execution_policy) }

  describe "#execute" do
    let(:main_relation) { Ci::Build.all }
    let(:sources) { ["scan_execution_policy"] }
    let(:cursor_id) { nil }

    subject(:build_source_finder) do
      described_class.new(
        relation: main_relation,
        sources: sources,
        project: pipeline.project,
        params: {
          cursor_id: cursor_id
        }
      ).execute
    end

    it 'filters by source in desc order' do
      expect(build_source_finder)
        .to eq([new_build, middle_build, old_build])
    end

    context 'when no source is passed in' do
      let(:sources) { [] }

      it 'does not filter by source' do
        expect(build_source_finder.count).to eq(6)
      end
    end

    context 'with multiple source query' do
      let(:sources) { %w[scan_execution_policy push] }

      it 'returns builds from any of the given sources' do
        expect(build_source_finder)
          .to eq([new_build, middle_new_build, middle_build, old_build])
      end
    end

    context 'when relation is Ci::Bridge' do
      let_it_be(:bridge_without_source) { create(:ci_bridge, pipeline: pipeline, name: "bridge1") }
      let_it_be(:trigger_bridge) { create(:ci_bridge, pipeline: pipeline, name: "bridge2") }
      let_it_be(:push_bridge) { create(:ci_bridge, pipeline: pipeline, name: "bridge4") }
      let_it_be(:scan_execution_policy_bridge) { create(:ci_bridge, pipeline: pipeline, name: "bridge5") }

      let_it_be(:trigger_source) { create(:ci_build_source, job: trigger_bridge, source: :trigger) }
      let_it_be(:push_source) { create(:ci_build_source, job: push_bridge, source: :push) }
      let_it_be(:scan_execution_policy_source) do
        create(:ci_build_source, job: scan_execution_policy_bridge, source: :scan_execution_policy)
      end

      let(:main_relation) { Ci::Bridge.all }

      it 'returns bridges from any of the given sources' do
        expect(build_source_finder).to eq([scan_execution_policy_bridge])
      end

      context 'with multiple source query' do
        let(:sources) { %w[scan_execution_policy push] }

        it 'returns bridges from any of the given sources' do
          expect(build_source_finder).to match_array([scan_execution_policy_bridge, push_bridge])
        end
      end
    end

    context 'with status and ref' do
      let(:main_relation) { Ci::Build.pending.where(ref: 'main') }

      it 'returns the correct builds with the filtered status and ref' do
        expect(build_source_finder.pluck(:name))
          .to eq(%w[build5 build3 build1])
        expect(build_source_finder.pluck(:ref).uniq)
          .to eq(%w[main])
        expect(build_source_finder.pluck(:status).uniq)
          .to eq(%w[pending])
      end
    end
  end
end
