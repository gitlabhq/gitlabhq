# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildNameFinder, feature_category: :continuous_integration do
  let_it_be(:pipeline) { create(:ci_pipeline) }
  let_it_be(:build_non_relevant) { create(:ci_build, :with_build_name, pipeline: pipeline, name: "unique-name") }
  let_it_be(:build_test) { create(:ci_build, :with_build_name, pipeline: pipeline, name: "build test") }
  let_it_be(:build_deploy) { create(:ci_build, :with_build_name, pipeline: pipeline, name: "build deploy") }
  let_it_be(:build_test_deploy) { create(:ci_build, :with_build_name, pipeline: pipeline, name: "build test deploy") }
  let_it_be(:multi_search_term) { create(:ci_build, :with_build_name, pipeline: pipeline, name: "a b c d e f") }

  describe "#execute" do
    let(:main_relation) { Ci::Build.all }
    let(:name) { "build" }

    subject(:build_name_finder) do
      described_class.new(
        relation: main_relation,
        name: name,
        project: pipeline.project
      ).execute
    end

    it 'filters by name' do
      expect(build_name_finder).to match_array([build_test, build_deploy, build_test_deploy])
    end

    context 'when a multi-term name is passed in' do
      let(:name) { "a b c d e z z z" }

      it 'filters and restricts search term' do
        expect(build_name_finder).to eq([multi_search_term])
      end
    end

    context 'when no name is passed in' do
      let(:name) { nil }

      it 'does not filter by name' do
        expect(build_name_finder.count).to eq(5)
      end
    end

    describe 'argument errors' do
      context 'when relation is not Ci::Build' do
        let(:main_relation) { Ci::Bridge.all }

        it 'raises argument error for relation' do
          expect { build_name_finder.execute }.to raise_error(ArgumentError, 'Only Ci::Builds are name searchable')
        end
      end
    end
  end
end
