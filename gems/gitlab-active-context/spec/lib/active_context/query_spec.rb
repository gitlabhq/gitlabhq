# frozen_string_literal: true

RSpec.describe ActiveContext::Query do
  describe 'class methods' do
    describe '.filter' do
      it 'creates a filter query with valid conditions' do
        query = described_class.filter(project_id: 1)
        expect(query.type).to eq(:filter)
        expect(query.value).to eq(project_id: 1)
      end

      it 'raises an error for empty conditions' do
        expect { described_class.filter }.to raise_error(ArgumentError, "Filter cannot be empty")
      end
    end

    describe '.prefix' do
      it 'creates a prefix query with valid conditions' do
        query = described_class.prefix(traversal_ids: '9970-')
        expect(query.type).to eq(:prefix)
        expect(query.value).to eq(traversal_ids: '9970-')
      end

      it 'raises an error for empty conditions' do
        expect { described_class.prefix }.to raise_error(ArgumentError, "Prefix cannot be empty")
      end
    end

    describe '.or' do
      it 'creates an OR query with multiple queries' do
        query1 = described_class.filter(project_id: 1)
        query2 = described_class.prefix(traversal_ids: 1)

        or_query = described_class.or(query1, query2)

        expect(or_query.type).to eq(:or)
        expect(or_query.children).to contain_exactly(query1, query2)
      end

      it 'raises an error for empty queries' do
        expect { described_class.or }.to raise_error(ArgumentError, "Or cannot be empty")
      end
    end

    describe '.and' do
      it 'creates an AND query with multiple queries' do
        query1 = described_class.filter(project_id: 1)
        query2 = described_class.filter(status: 'active')

        and_query = described_class.and(query1, query2)

        expect(and_query.type).to eq(:and)
        expect(and_query.children).to contain_exactly(query1, query2)
      end

      it 'raises an error for empty queries' do
        expect { described_class.and }.to raise_error(ArgumentError, "And cannot be empty")
      end
    end
  end

  describe 'instance methods' do
    describe '#or' do
      it 'creates a new query with OR logic' do
        base_query = described_class.filter(project_id: 1)
        additional_query1 = described_class.filter(status: 'active')
        additional_query2 = described_class.prefix(traversal_ids: '9970-')

        or_query = base_query.or(additional_query1, additional_query2)

        expect(or_query.type).to eq(:and)
        expect(or_query.children.size).to eq(2)
        expect(or_query.children.first).to eq(base_query)

        or_child = or_query.children.last
        expect(or_child.type).to eq(:or)
        expect(or_child.children).to contain_exactly(additional_query1, additional_query2)
      end

      it 'raises an error for empty queries' do
        base_query = described_class.filter(project_id: 1)
        expect { base_query.or }.to raise_error(ArgumentError, "Or cannot be empty")
      end
    end

    describe '#and' do
      it 'creates a new query with AND logic' do
        base_query = described_class.filter(project_id: 1)
        additional_query = described_class.filter(status: 'active')

        and_query = base_query.and(additional_query)

        expect(and_query.type).to eq(:and)
        expect(and_query.children).to contain_exactly(base_query, additional_query)
      end

      it 'raises an error for empty queries' do
        base_query = described_class.filter(project_id: 1)
        expect { base_query.and }.to raise_error(ArgumentError, "And cannot be empty")
      end
    end

    describe '#limit' do
      it 'creates a limit query' do
        base_query = described_class.filter(project_id: 1)
        limited_query = base_query.limit(5)

        expect(limited_query.type).to eq(:limit)
        expect(limited_query.value).to eq(5)
        expect(limited_query.children).to contain_exactly(base_query)
      end

      it 'raises an error for nil limit' do
        base_query = described_class.filter(project_id: 1)
        expect { base_query.limit(nil) }.to raise_error(ArgumentError, "Limit cannot be empty")
      end

      it 'raises an error for non-integer limit' do
        base_query = described_class.filter(project_id: 1)
        expect { base_query.limit('5') }.to raise_error(ArgumentError, /Limit must be a number/)
      end
    end

    describe '#knn' do
      it 'creates a KNN query with limit' do
        base_query = described_class.filter(project_id: 1)
        vector = [0.1, 0.2, 0.3]
        knn_query = base_query.knn(target: 'similarity', vector: vector, limit: 5)

        expect(knn_query.type).to eq(:knn)
        expect(knn_query.value).to eq(
          target: 'similarity',
          vector: vector,
          limit: 5
        )
        expect(knn_query.children).to contain_exactly(base_query)
      end

      it 'raises an error for nil target' do
        base_query = described_class.filter(project_id: 1)
        vector = [0.1, 0.2, 0.3]
        expect { base_query.knn(target: nil, vector: vector, limit: 5) }
          .to raise_error(ArgumentError, "Target cannot be nil")
      end

      it 'raises an error for nil limit' do
        base_query = described_class.filter(project_id: 1)
        vector = [0.1, 0.2, 0.3]
        expect { base_query.knn(target: 'similarity', vector: vector, limit: nil) }
          .to raise_error(ArgumentError, /Limit must be a positive number/)
      end

      it 'raises an error for non-array vector' do
        base_query = described_class.filter(project_id: 1)
        expect do
          base_query.knn(target: 'similarity', vector: 'not an array', limit: 5)
        end.to raise_error(ArgumentError, "Vector must be an array")
      end

      it 'raises an error for non-positive limit' do
        base_query = described_class.filter(project_id: 1)
        vector = [0.1, 0.2, 0.3]

        expect do
          base_query.knn(target: 'similarity', vector: vector, limit: 0)
        end.to raise_error(ArgumentError, /Limit must be a positive number/)

        expect do
          base_query.knn(target: 'similarity', vector: vector, limit: -1)
        end.to raise_error(ArgumentError, /Limit must be a positive number/)
      end
    end

    describe '#inspect_ast' do
      it 'generates a readable AST representation for a simple filter query' do
        query = described_class.filter(project_id: 1)
        ast = query.inspect_ast
        expect(ast).to eq('filter(project_id: 1)')
      end

      it 'generates a readable AST representation for a complex nested query' do
        complex_query = described_class.filter(hello: :foo)
          .or(
            described_class.filter(project_id: 1),
            described_class.prefix(traversal_ids: '9970-')
          )

        ast = complex_query.inspect_ast
        expect(ast).to include('and')
        expect(ast).to include('filter(hello: foo)')
        expect(ast).to include('or')
        expect(ast).to include('filter(project_id: 1)')
        expect(ast).to include('prefix(traversal_ids: 9970-)')
      end

      it 'generates a readable AST representation for a KNN query with limit' do
        base_query = described_class.filter(project_id: 1)
        vector = [0.1, 0.2, 0.3]
        knn_query = base_query.knn(target: 'similarity', vector: vector, limit: 5)

        ast = knn_query.inspect_ast
        expect(ast).to eq("knn(target: similarity, vector: [0.1, 0.2, 0.3], limit: 5)\n  filter(project_id: 1)")
      end

      it 'generates a readable AST representation for a KNN query without a base query' do
        vector = [0.1, 0.2, 0.3]
        knn_query = described_class.knn(target: 'similarity', vector: vector, limit: 5)

        ast = knn_query.inspect_ast
        expect(ast).to eq('knn(target: similarity, vector: [0.1, 0.2, 0.3], limit: 5)')
      end
    end

    describe 'initialization' do
      it 'raises an error for invalid query type' do
        expect { described_class.new(type: :invalid) }.to raise_error(
          ArgumentError,
          /Invalid type: invalid\. Allowed types are: filter, prefix, limit, knn, and, or/
        )
      end
    end
  end
end
