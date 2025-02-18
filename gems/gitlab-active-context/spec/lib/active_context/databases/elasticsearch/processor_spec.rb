# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveContext::Databases::Elasticsearch::Processor do
  it_behaves_like 'a query processor'

  describe '#process' do
    subject(:processor) { described_class.new }

    let(:simple_filter) { ActiveContext::Query.filter(status: 'active') }
    let(:simple_prefix) { ActiveContext::Query.prefix(name: 'test') }
    let(:simple_knn) do
      ActiveContext::Query.knn(
        target: 'embedding',
        vector: [0.1, 0.2],
        limit: 5
      )
    end

    context 'with filter queries' do
      it 'creates a term query for exact matches' do
        query = ActiveContext::Query.filter(status: 'active', project_id: 123)
        result = processor.process(query)

        expect(result).to eq(
          query: {
            bool: {
              must: [
                { term: { status: 'active' } },
                { term: { project_id: 123 } }
              ]
            }
          }
        )
      end

      it 'creates a terms query for array values' do
        query = ActiveContext::Query.filter(project_id: [1, 2, 3])
        result = processor.process(query)

        expect(result).to eq(
          query: {
            bool: {
              must: [
                { terms: { project_id: [1, 2, 3] } }
              ]
            }
          }
        )
      end

      it 'handles mixed term and terms queries' do
        query = ActiveContext::Query.filter(
          status: 'active',
          project_id: [1, 2, 3],
          category: 'product'
        )
        result = processor.process(query)

        expect(result).to eq(
          query: {
            bool: {
              must: [
                { term: { status: 'active' } },
                { terms: { project_id: [1, 2, 3] } },
                { term: { category: 'product' } }
              ]
            }
          }
        )
      end

      it 'combines multiple filter queries with array values in must clauses' do
        filter1 = ActiveContext::Query.filter(status: %w[active pending])
        filter2 = ActiveContext::Query.filter(category: 'product')
        query = ActiveContext::Query.and(filter1, filter2)

        result = processor.process(query)

        expect(result).to eq(
          query: {
            bool: {
              must: [
                { bool: { must: [{ terms: { status: %w[active pending] } }] } },
                { bool: { must: [{ term: { category: 'product' } }] } }
              ]
            }
          }
        )
      end

      it 'combines multiple filter queries in must clauses' do
        filter1 = ActiveContext::Query.filter(status: 'active')
        filter2 = ActiveContext::Query.filter(category: 'product')
        query = ActiveContext::Query.and(filter1, filter2)

        result = processor.process(query)

        expect(result).to eq(
          query: {
            bool: {
              must: [
                { bool: { must: [{ term: { status: 'active' } }] } },
                { bool: { must: [{ term: { category: 'product' } }] } }
              ]
            }
          }
        )
      end
    end

    context 'with prefix queries' do
      it 'creates a prefix query for starts-with matches' do
        query = ActiveContext::Query.prefix(name: 'test', path: 'foo/')
        result = processor.process(query)

        expect(result).to eq(
          query: {
            bool: {
              must: [
                { prefix: { name: 'test' } },
                { prefix: { path: 'foo/' } }
              ]
            }
          }
        )
      end
    end

    context 'with OR queries' do
      it 'creates a should query with minimum_should_match' do
        query = ActiveContext::Query.or(simple_filter, simple_prefix)
        result = processor.process(query)

        expect(result).to eq(
          query: {
            bool: {
              should: [
                { bool: { must: [{ term: { status: 'active' } }] } },
                { bool: { must: [{ prefix: { name: 'test' } }] } }
              ],
              minimum_should_match: 1
            }
          }
        )
      end

      it 'handles terms queries in OR conditions' do
        filter1 = ActiveContext::Query.filter(project_id: [1, 2, 3])
        filter2 = ActiveContext::Query.filter(status: 'active')
        query = ActiveContext::Query.or(filter1, filter2)

        result = processor.process(query)

        expect(result).to eq(
          query: {
            bool: {
              should: [
                { bool: { must: [{ terms: { project_id: [1, 2, 3] } }] } },
                { bool: { must: [{ term: { status: 'active' } }] } }
              ],
              minimum_should_match: 1
            }
          }
        )
      end

      context 'when containing KNN' do
        it 'combines KNN with other conditions' do
          query = ActiveContext::Query.or(simple_knn, simple_filter)
          result = processor.process(query)

          expect(result).to eq(
            knn: {
              field: 'embedding',
              query_vector: [0.1, 0.2],
              k: 5,
              num_candidates: 50
            },
            query: {
              bool: {
                should: [
                  { bool: { must: [{ term: { status: 'active' } }] } }
                ],
                minimum_should_match: 1
              }
            }
          )
        end

        it 'returns only KNN query when no other conditions' do
          query = ActiveContext::Query.or(simple_knn)
          result = processor.process(query)

          expect(result).to eq(
            knn: {
              field: 'embedding',
              query_vector: [0.1, 0.2],
              k: 5,
              num_candidates: 50
            }
          )
        end
      end
    end

    context 'with AND queries' do
      it 'creates a must query combining conditions' do
        query = ActiveContext::Query.and(simple_filter, simple_prefix)
        result = processor.process(query)

        expect(result).to eq(
          query: {
            bool: {
              must: [
                { bool: { must: [{ term: { status: 'active' } }] } },
                { bool: { must: [{ prefix: { name: 'test' } }] } }
              ]
            }
          }
        )
      end
    end

    context 'with KNN queries' do
      it 'creates a basic KNN query' do
        result = processor.process(simple_knn)

        expect(result).to eq(
          knn: {
            field: 'embedding',
            query_vector: [0.1, 0.2],
            k: 5,
            num_candidates: 50
          }
        )
      end

      it 'applies filters inside the KNN query' do
        query = simple_filter.knn(
          target: 'embedding',
          vector: [0.1, 0.2],
          limit: 5
        )

        result = processor.process(query)

        expect(result).to eq(
          knn: {
            field: 'embedding',
            query_vector: [0.1, 0.2],
            k: 5,
            num_candidates: 50,
            filter: {
              bool: {
                must: [{ term: { status: 'active' } }]
              }
            }
          }
        )
      end

      it 'handles terms filter inside KNN query' do
        filter = ActiveContext::Query.filter(project_id: [1, 2, 3])
        query = filter.knn(
          target: 'embedding',
          vector: [0.1, 0.2],
          limit: 5
        )

        result = processor.process(query)

        expect(result).to eq(
          knn: {
            field: 'embedding',
            query_vector: [0.1, 0.2],
            k: 5,
            num_candidates: 50,
            filter: {
              bool: {
                must: [{ terms: { project_id: [1, 2, 3] } }]
              }
            }
          }
        )
      end

      it 'handles multiple filter conditions inside KNN query' do
        filter1 = ActiveContext::Query.filter(status: 'active')
        filter2 = ActiveContext::Query.filter(category: 'product')
        base_query = ActiveContext::Query.and(filter1, filter2)

        query = base_query.knn(
          target: 'embedding',
          vector: [0.1, 0.2],
          limit: 5
        )

        result = processor.process(query)

        expect(result).to eq(
          knn: {
            field: 'embedding',
            query_vector: [0.1, 0.2],
            k: 5,
            num_candidates: 50,
            filter: {
              bool: {
                must: [
                  { bool: { must: [{ term: { status: 'active' } }] } },
                  { bool: { must: [{ term: { category: 'product' } }] } }
                ]
              }
            }
          }
        )
      end

      it 'properly handles KNN with both prefix and filter conditions inside KNN query' do
        filter = ActiveContext::Query.filter(status: 'active')
        prefix = ActiveContext::Query.prefix(name: 'test')
        base_query = ActiveContext::Query.and(filter, prefix)

        query = base_query.knn(
          target: 'embedding',
          vector: [0.1, 0.2],
          limit: 5
        )

        result = processor.process(query)

        expect(result).to eq(
          knn: {
            field: 'embedding',
            query_vector: [0.1, 0.2],
            k: 5,
            num_candidates: 50,
            filter: {
              bool: {
                must: [
                  { bool: { must: [{ term: { status: 'active' } }] } },
                  { bool: { must: [{ prefix: { name: 'test' } }] } }
                ]
              }
            }
          }
        )
      end
    end

    context 'with limit queries' do
      it 'adds size parameter to the query' do
        query = simple_filter.limit(10)
        result = processor.process(query)

        expect(result).to eq(
          query: {
            bool: {
              must: [{ term: { status: 'active' } }]
            }
          },
          size: 10
        )
      end

      it 'adds size parameter to KNN query' do
        query = simple_knn.limit(10)
        result = processor.process(query)

        expect(result).to eq(
          knn: {
            field: 'embedding',
            query_vector: [0.1, 0.2],
            k: 5,
            num_candidates: 50
          },
          size: 10
        )
      end
    end
  end
end
