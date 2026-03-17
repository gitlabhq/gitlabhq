# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveContext::Databases::Postgresql::Processor, feature_category: :global_search do
  let(:client) { instance_double(ActiveContext::Databases::Postgresql::Client) }
  let(:adapter) { instance_double(ActiveContext::Databases::Postgresql::Adapter, client: client) }

  let(:collection) do
    klass = Class.new(Test::Collections::Mock) do
      def self.collection_name
        'items'
      end
    end

    allow(klass).to receive(:collection_record).and_return(
      double("CollectionRecord", search_embedding_model: { field: 'preset_field', model_ref: 'model_001' })
    )

    klass
  end

  let(:model) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'items'
    end
  end

  before(:all) do
    config_path = File.expand_path('../../../../../../../config/database.yml', __dir__)
    database_config = YAML.load_file(config_path)[ENV.fetch('RAILS_ENV', 'test')]['main']
    ActiveRecord::Base.establish_connection(database_config)

    ActiveRecord::Base.connection.create_table :items
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table :items
  end

  before do
    allow(client).to receive(:with_model_for).with('items').and_yield(model)
    allow(ActiveContext).to receive(:adapter).and_return(adapter)
  end

  shared_examples 'a SQL transformer' do |query, expected_sql|
    it 'generates the expected SQL' do
      result = described_class.transform(collection: collection, node: query, user: double)
      expect(result).to eq(expected_sql)
    end
  end

  context 'with filter queries' do
    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(status: 'active', project_id: 123),
      "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"status\" = 'active') AND (\"items\".\"project_id\" = 123)"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(project_id: [1, 2, 3]),
      "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"project_id\" IN (1, 2, 3))"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(status: 'active', project_id: [1, 2, 3], category: 'product'),
      "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"status\" = 'active') " \
        "AND (\"items\".\"project_id\" IN (1, 2, 3)) AND (\"items\".\"category\" = 'product')"
  end

  context 'with prefix queries' do
    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.prefix(name: 'test', path: 'foo/'),
      "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"name\" LIKE 'test%') AND (\"items\".\"path\" LIKE 'foo/%')"
  end

  context 'with AND queries' do
    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.and(
        ActiveContext::Query.filter(status: %w[active pending]),
        ActiveContext::Query.filter(category: 'product')
      ),
      "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"status\" IN ('active', 'pending')) " \
        "AND (\"items\".\"category\" = 'product')"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.and(
        ActiveContext::Query.filter(status: 'active'),
        ActiveContext::Query.prefix(name: 'test')
      ),
      "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"status\" = 'active') AND (\"items\".\"name\" LIKE 'test%')"

    context 'when containing KNN' do
      it_behaves_like 'a SQL transformer',
        ActiveContext::Query.and(
          ActiveContext::Query.knn(
            target: 'embedding',
            vector: [0.1, 0.2],
            k: 5
          ),
          ActiveContext::Query.filter(status: 'active')
        ),
        "SELECT \"items\".*, ((2.0 - (\"items\".\"embedding\" <=> '[0.1,0.2]')) / 2.0) AS score " \
          "FROM \"items\" WHERE (\"items\".\"status\" = 'active') " \
          "ORDER BY \"items\".\"embedding\" <=> '[0.1,0.2]' LIMIT 5"
    end
  end

  context 'with OR queries' do
    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.or(
        ActiveContext::Query.filter(project_id: [1, 2, 3]),
        ActiveContext::Query.filter(status: 'active')
      ),
      "SELECT \"items\".* FROM \"items\" WHERE ((\"items\".\"project_id\" IN (1, 2, 3)) " \
        "OR (\"items\".\"status\" = 'active'))"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.or(
        ActiveContext::Query.filter(status: 'active'),
        ActiveContext::Query.prefix(name: 'test')
      ),
      "SELECT \"items\".* FROM \"items\" WHERE ((\"items\".\"status\" = 'active') OR (\"items\".\"name\" LIKE 'test%'))"

    context 'when containing KNN' do
      it_behaves_like 'a SQL transformer',
        ActiveContext::Query.or(
          ActiveContext::Query.knn(
            target: 'embedding',
            vector: [0.1, 0.2],
            k: 5
          )
        ),
        "SELECT \"items\".*, ((2.0 - (\"items\".\"embedding\" <=> '[0.1,0.2]')) / 2.0) AS score " \
          "FROM \"items\" ORDER BY \"items\".\"embedding\" <=> '[0.1,0.2]' LIMIT 5"

      it_behaves_like 'a SQL transformer',
        ActiveContext::Query.or(
          ActiveContext::Query.knn(
            target: 'embedding',
            vector: [0.1, 0.2],
            k: 5
          ),
          ActiveContext::Query.filter(status: 'active')
        ),
        "SELECT \"items\".*, ((2.0 - (\"items\".\"embedding\" <=> '[0.1,0.2]')) / 2.0) AS score " \
          "FROM \"items\" WHERE (\"items\".\"status\" = 'active') " \
          "ORDER BY \"items\".\"embedding\" <=> '[0.1,0.2]' LIMIT 5"
    end
  end

  context 'with KNN queries' do
    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.knn(
        target: 'embedding',
        vector: [0.1, 0.2],
        k: 5
      ),
      "SELECT \"items\".*, ((2.0 - (\"items\".\"embedding\" <=> '[0.1,0.2]')) / 2.0) AS score " \
        "FROM \"items\" ORDER BY \"items\".\"embedding\" <=> '[0.1,0.2]' LIMIT 5"

    describe 'content-based KNN query' do
      before do
        allow_any_instance_of(::ActiveContext::EmbeddingModel).to receive(:generate_embeddings)
          .with('something', user: anything).and_return([[0.5, 0.6]])
      end

      it_behaves_like 'a SQL transformer',
        ActiveContext::Query.knn(
          content: 'something',
          k: 5
        ),
        "SELECT \"items\".*, ((2.0 - (\"items\".\"preset_field\" <=> '[0.5,0.6]')) / 2.0) AS score " \
          "FROM \"items\" ORDER BY \"items\".\"preset_field\" <=> '[0.5,0.6]' LIMIT 5"
    end

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(status: 'active').knn(
        target: 'embedding',
        vector: [0.1, 0.2],
        k: 5
      ),
      "SELECT \"items\".*, ((2.0 - (\"items\".\"embedding\" <=> '[0.1,0.2]')) / 2.0) AS score " \
        "FROM \"items\" WHERE (\"items\".\"status\" = 'active') " \
        "ORDER BY \"items\".\"embedding\" <=> '[0.1,0.2]' LIMIT 5"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(project_id: [1, 2, 3]).knn(
        target: 'embedding',
        vector: [0.1, 0.2],
        k: 5
      ),
      "SELECT \"items\".*, ((2.0 - (\"items\".\"embedding\" <=> '[0.1,0.2]')) / 2.0) AS score " \
        "FROM \"items\" WHERE (\"items\".\"project_id\" IN (1, 2, 3)) " \
        "ORDER BY \"items\".\"embedding\" <=> '[0.1,0.2]' LIMIT 5"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.and(
        ActiveContext::Query.filter(status: 'active'),
        ActiveContext::Query.filter(category: 'product')
      ).knn(
        target: 'embedding',
        vector: [0.1, 0.2],
        k: 5
      ),
      "SELECT \"items\".*, ((2.0 - (\"items\".\"embedding\" <=> '[0.1,0.2]')) / 2.0) AS score " \
        "FROM \"items\" WHERE (\"items\".\"status\" = 'active') " \
        "AND (\"items\".\"category\" = 'product') ORDER BY \"items\".\"embedding\" <=> '[0.1,0.2]' LIMIT 5"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.and(
        ActiveContext::Query.filter(status: 'active'),
        ActiveContext::Query.prefix(name: 'test')
      ).knn(
        target: 'embedding',
        vector: [0.1, 0.2],
        k: 5
      ),
      "SELECT \"items\".*, ((2.0 - (\"items\".\"embedding\" <=> '[0.1,0.2]')) / 2.0) AS score " \
        "FROM \"items\" WHERE (\"items\".\"status\" = 'active') " \
        "AND (\"items\".\"name\" LIKE 'test%') ORDER BY \"items\".\"embedding\" <=> '[0.1,0.2]' LIMIT 5"
  end

  context 'with limit queries' do
    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(status: 'active').limit(10),
      "SELECT subq.* FROM (SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"status\" = 'active')) subq LIMIT 10"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.knn(
        target: 'embedding',
        vector: [0.1, 0.2],
        k: 5
      ).limit(10),
      "SELECT subq.* FROM (SELECT \"items\".*, ((2.0 - (\"items\".\"embedding\" <=> '[0.1,0.2]')) / 2.0) AS score " \
        "FROM \"items\" ORDER BY \"items\".\"embedding\" <=> '[0.1,0.2]' LIMIT 5) subq LIMIT 10"
  end

  context 'with missing queries' do
    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.missing('embedding'),
      "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"embedding\" IS NULL)"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(status: 'active').missing('embedding'),
      "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"status\" = 'active') AND (\"items\".\"embedding\" IS NULL)"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(project_id: [1, 2, 3]).missing('embedding'),
      "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"project_id\" IN (1, 2, 3)) " \
        "AND (\"items\".\"embedding\" IS NULL)"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(status: 'active').missing('embedding').limit(10),
      "SELECT subq.* FROM (SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"status\" = 'active') " \
        "AND (\"items\".\"embedding\" IS NULL)) subq LIMIT 10"
  end

  context 'with exists queries' do
    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.exists('embedding'),
      "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"embedding\" IS NOT NULL)"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(status: 'active').exists('embedding'),
      "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"status\" = 'active') " \
        "AND (\"items\".\"embedding\" IS NOT NULL)"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(project_id: [1, 2, 3]).exists('embedding'),
      "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"project_id\" IN (1, 2, 3)) " \
        "AND (\"items\".\"embedding\" IS NOT NULL)"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(status: 'active').exists('embedding').limit(10),
      "SELECT subq.* FROM (SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"status\" = 'active') " \
        "AND (\"items\".\"embedding\" IS NOT NULL)) subq LIMIT 10"

    context 'when containing AND' do
      it_behaves_like 'a SQL transformer',
        ActiveContext::Query.and(
          ActiveContext::Query.exists('embedding'),
          ActiveContext::Query.filter(status: 'active')
        ),
        "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"embedding\" IS NOT NULL) " \
          "AND (\"items\".\"status\" = 'active')"

      it_behaves_like 'a SQL transformer',
        ActiveContext::Query.and(
          ActiveContext::Query.filter(status: 'active'),
          ActiveContext::Query.exists('embedding')
        ),
        "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"status\" = 'active') AND " \
          "(\"items\".\"embedding\" IS NOT NULL)"

      it_behaves_like 'a SQL transformer',
        ActiveContext::Query.and(
          ActiveContext::Query.filter(project_id: [1, 2, 3]),
          ActiveContext::Query.exists('embedding')
        ),
        "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"project_id\" IN (1, 2, 3)) " \
          "AND (\"items\".\"embedding\" IS NOT NULL)"
    end

    context 'when containing OR' do
      it_behaves_like 'a SQL transformer',
        ActiveContext::Query.or(
          ActiveContext::Query.exists('embedding_v1'),
          ActiveContext::Query.exists('embedding_v2')
        ),
        "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"embedding_v1\" IS NOT NULL " \
          "OR \"items\".\"embedding_v2\" IS NOT NULL)"

      it_behaves_like 'a SQL transformer',
        ActiveContext::Query.or(
          ActiveContext::Query.exists('embedding'),
          ActiveContext::Query.filter(status: 'active')
        ),
        "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"embedding\" IS NOT NULL " \
          "OR (\"items\".\"status\" = 'active'))"

      it_behaves_like 'a SQL transformer',
        ActiveContext::Query.or(
          ActiveContext::Query.filter(status: 'active'),
          ActiveContext::Query.exists('embedding')
        ),
        "SELECT \"items\".* FROM \"items\" WHERE ((\"items\".\"status\" = 'active') " \
          "OR \"items\".\"embedding\" IS NOT NULL)"
    end
  end

  context 'with all queries' do
    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.all,
      "SELECT \"items\".* FROM \"items\""
  end
end
