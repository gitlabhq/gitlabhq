# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::CountableConnectionType do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  let(:connection_type) { GitlabSchema.types['PipelineConnection'] }

  it 'has the expected fields' do
    expected_fields = %i[count page_info edges nodes]

    expect(connection_type).to have_graphql_fields(*expected_fields)
  end

  describe 'count field' do
    let(:count_field) { connection_type.fields['count'] }

    it 'has a limit argument' do
      expect(count_field.arguments).to have_key('limit')
    end

    it 'has the correct description' do
      expect(count_field.description)
        .to eq('Total count of collection. Returns limit + 1 for counts greater than the limit.')
    end

    describe 'limit argument' do
      let(:limit_argument) { count_field.arguments['limit'] }

      it 'is optional' do
        expect(limit_argument.type.non_null?).to be(false)
      end
    end
  end

  describe '#count' do
    let_it_be(:pipelines) { create_list(:ci_pipeline, 5, project: project) }
    let(:count_result) { subject.dig('data', 'project', 'pipelines', 'count') }

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    context 'without limit argument' do
      let(:query) do
        %(
          {
            project(fullPath: "#{project.full_path}") {
              pipelines {
                count
              }
            }
          }
        )
      end

      it 'returns the exact count' do
        expect(count_result).to eq(5)
      end

      context 'with grouped relation' do
        it 'returns the count of unique groups' do
          # Create pipelines with different statuses to test grouped counting
          create(:ci_pipeline, project: project, status: :success)
          create(:ci_pipeline, project: project, status: :failed)

          expect(count_result).to eq(7)
        end
      end
    end

    context 'with limit argument' do
      context 'when count is below limit' do
        let(:query) do
          %(
            {
              project(fullPath: "#{project.full_path}") {
                pipelines {
                  count(limit: 10)
                }
              }
            }
          )
        end

        it 'returns the limited count when below limit' do
          expect(count_result).to eq(5)
        end
      end

      context 'when count exceeds limit' do
        let(:query) do
          %(
            {
              project(fullPath: "#{project.full_path}") {
                pipelines {
                  count(limit: 3)
                }
              }
            }
          )
        end

        it 'returns limit + 1 when count exceeds limit' do
          expect(count_result).to eq(4)
        end
      end

      context 'with paginated relations' do
        let(:query) do
          %(
            {
              project(fullPath: "#{project.full_path}") {
                pipelines(first: 2) {
                  count(limit: 10)
                }
              }
            }
          )
        end

        it 'returns the exact count' do
          expect(count_result).to eq(5)
        end
      end
    end

    context 'when the items expose a precomputed_total_count' do
      let(:type) do
        described_class.allocate.tap do |instance|
          allow(instance).to receive(:object).and_return(connection)
        end
      end

      let(:connection) { Struct.new(:items).new(items) }
      let(:items) do
        Gitlab::Graphql::ExternallyPaginatedArray.new(nil, nil, :page_item_a, :page_item_b, total_count: total_count)
      end

      context 'when the precomputed total is present' do
        let(:total_count) { 42 }

        it 'returns the precomputed total', :aggregate_failures do
          expect(type.count).to eq(42)
          expect(items.size).to eq(2)
        end

        it 'caps at limit + 1 when a smaller limit is given' do
          expect(type.count(limit: 10)).to eq(11)
        end

        it 'returns the precomputed total when it is below the limit' do
          expect(type.count(limit: 100)).to eq(42)
        end
      end

      context 'when the precomputed total is nil' do
        let(:total_count) { nil }

        it 'falls back to the existing page-size behavior' do
          expect(type.count).to eq(2)
        end
      end
    end
  end
end
