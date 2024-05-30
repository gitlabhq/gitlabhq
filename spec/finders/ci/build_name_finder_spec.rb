# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildNameFinder, feature_category: :continuous_integration do
  let_it_be(:pipeline) { create(:ci_pipeline) }
  let_it_be(:build_non_relevant) { create(:ci_build, :with_build_name, pipeline: pipeline, name: "unique-name") }
  let_it_be(:old_build) { create(:ci_build, :with_build_name, pipeline: pipeline, name: "build1") }
  let_it_be(:old_middle_build) { create(:ci_build, :with_build_name, pipeline: pipeline, name: "build2") }
  let_it_be(:middle_build) { create(:ci_build, :with_build_name, pipeline: pipeline, name: "build3") }
  let_it_be(:middle_new_build) { create(:ci_build, :with_build_name, pipeline: pipeline, name: "build4") }
  let_it_be(:new_build) { create(:ci_build, :with_build_name, pipeline: pipeline, name: "build5") }

  describe "#execute" do
    let(:main_relation) { Ci::Build.all }
    let(:name) { "build" }
    let(:before) { nil }
    let(:after) { nil }
    let(:asc) { nil }
    let(:invert_ordering) { false }

    subject(:build_name_finder) do
      described_class.new(
        relation: main_relation,
        name: name,
        project: pipeline.project,
        params: {
          before: before, after: after, asc: asc,
          invert_ordering: invert_ordering
        }
      ).execute
    end

    it 'filters by name in desc order' do
      expect(build_name_finder)
        .to eq([new_build, middle_new_build, middle_build, old_middle_build, old_build])
    end

    context 'when no name is passed in' do
      let(:name) { nil }

      it 'does not filter by name' do
        expect(build_name_finder.count).to eq(6)
      end
    end

    describe 'argument errors' do
      context 'when relation is not Ci::Build' do
        let(:main_relation) { Ci::Bridge.all }

        it 'raises argument error for relation' do
          expect { build_name_finder.execute }.to raise_error(ArgumentError, 'Only Ci::Builds are name searchable')
        end
      end

      context 'when relation is using offset' do
        it 'raises argument error for params' do
          expect do
            described_class.new(
              relation: main_relation.offset(1),
              name: name,
              project: pipeline.project,
              params: {}
            )
            .execute
          end.to raise_error(ArgumentError, 'Offset Pagination is not supported')
        end
      end
    end

    context 'with before param' do
      let(:before) { middle_build.id }

      it 'returns builds newer than middle build' do
        expect(build_name_finder)
          .to eq([new_build, middle_new_build])
      end

      context 'with asc param' do
        let(:asc) { true }

        it 'returns only the builds in asc order' do
          expect(build_name_finder)
            .to eq([middle_new_build, new_build])
        end
      end
    end

    context 'with after param' do
      let(:after) { middle_build.id }

      it 'returns builds older than middle build' do
        expect(build_name_finder)
          .to eq([old_middle_build, old_build])
      end

      context 'with asc param' do
        let(:asc) { true }

        it 'returns build before cursor in asc order' do
          expect(build_name_finder)
            .to eq([old_build, old_middle_build])
        end
      end
    end

    context 'with asc param' do
      let(:asc) { true }

      it 'returns the records in ascending order' do
        expect(build_name_finder).to eq([old_build, old_middle_build, middle_build, middle_new_build, new_build])
      end
    end
  end
end
