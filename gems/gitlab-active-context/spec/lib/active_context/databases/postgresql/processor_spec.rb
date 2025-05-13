# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveContext::Databases::Postgresql::Processor, feature_category: :global_search do
  let(:client) { instance_double(ActiveContext::Databases::Postgresql::Client) }
  let(:adapter) { instance_double(ActiveContext::Databases::Postgresql::Adapter, client: client) }
  let(:user) { double }
  let(:generated_embedding) { [0.5, 0.6] }
  let(:collection_name) { 'items' }
  let(:collection) do
    double(collection_name: collection_name, current_search_embedding_version: { field: 'preset_field', model: model })
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
    allow(client).to receive(:with_model_for).with(collection_name).and_yield(model)
    allow(ActiveContext).to receive(:adapter).and_return(adapter)
    allow(ActiveContext::Embeddings).to receive(:generate_embeddings)
      .with(anything, model: model, user: user).and_return([generated_embedding])
  end

  shared_examples 'a SQL transformer' do |query, expected_sql|
    it 'generates the expected SQL' do
      result = described_class.transform(collection: collection, node: query, user: user)
      expect(result).to eq(expected_sql)
    end
  end

  context 'with filter queries' do
    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(status: 'active', project_id: 123),
      "SELECT \"items\".* FROM \"items\" WHERE \"items\".\"status\" = 'active' AND \"items\".\"project_id\" = 123"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(project_id: [1, 2, 3]),
      "SELECT \"items\".* FROM \"items\" WHERE \"items\".\"project_id\" IN (1, 2, 3)"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(status: 'active', project_id: [1, 2, 3], category: 'product'),
      "SELECT \"items\".* FROM \"items\" WHERE \"items\".\"status\" = 'active' " \
        "AND \"items\".\"project_id\" IN (1, 2, 3) AND \"items\".\"category\" = 'product'"
  end

  context 'with prefix queries' do
    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.prefix(name: 'test', path: 'foo/'),
      "SELECT \"items\".* FROM \"items\" WHERE (\"name\" LIKE 'test%') AND (\"path\" LIKE 'foo/%')"
  end

  context 'with AND queries' do
    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.and(
        ActiveContext::Query.filter(status: %w[active pending]),
        ActiveContext::Query.filter(category: 'product')
      ),
      "SELECT \"items\".* FROM \"items\" WHERE \"items\".\"status\" IN ('active', 'pending') " \
        "AND \"items\".\"category\" = 'product'"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.and(
        ActiveContext::Query.filter(status: 'active'),
        ActiveContext::Query.prefix(name: 'test')
      ),
      "SELECT \"items\".* FROM \"items\" WHERE \"items\".\"status\" = 'active' AND (\"name\" LIKE 'test%')"

    context 'when containing KNN' do
      it_behaves_like 'a SQL transformer',
        ActiveContext::Query.and(
          ActiveContext::Query.knn(
            target: 'embedding',
            vector: [0.1, 0.2],
            limit: 5
          ),
          ActiveContext::Query.filter(status: 'active')
        ),
        "SELECT \"items\".* FROM \"items\" WHERE \"items\".\"status\" = 'active' " \
          "ORDER BY \"embedding\" <=> '[0.1,0.2]' LIMIT 5"
    end
  end

  context 'with OR queries' do
    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.or(
        ActiveContext::Query.filter(project_id: [1, 2, 3]),
        ActiveContext::Query.filter(status: 'active')
      ),
      "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"project_id\" IN (1, 2, 3) " \
        "OR \"items\".\"status\" = 'active')"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.or(
        ActiveContext::Query.filter(status: 'active'),
        ActiveContext::Query.prefix(name: 'test')
      ),
      "SELECT \"items\".* FROM \"items\" WHERE (\"items\".\"status\" = 'active' OR (\"name\" LIKE 'test%'))"

    context 'when containing KNN' do
      it_behaves_like 'a SQL transformer',
        ActiveContext::Query.or(
          ActiveContext::Query.knn(
            target: 'embedding',
            vector: [0.1, 0.2],
            limit: 5
          )
        ),
        "SELECT \"items\".* FROM \"items\" ORDER BY \"embedding\" <=> '[0.1,0.2]' LIMIT 5"

      it_behaves_like 'a SQL transformer',
        ActiveContext::Query.or(
          ActiveContext::Query.knn(
            target: 'embedding',
            vector: [0.1, 0.2],
            limit: 5
          ),
          ActiveContext::Query.filter(status: 'active')
        ),
        "SELECT \"items\".* FROM \"items\" WHERE \"items\".\"status\" = 'active' " \
          "ORDER BY \"embedding\" <=> '[0.1,0.2]' LIMIT 5"
    end
  end

  context 'with KNN queries' do
    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.knn(
        target: 'embedding',
        vector: [0.1, 0.2],
        limit: 5
      ),
      "SELECT \"items\".* FROM \"items\" ORDER BY \"embedding\" <=> '[0.1,0.2]' LIMIT 5"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.knn(
        content: 'something',
        limit: 5
      ),
      "SELECT \"items\".* FROM \"items\" ORDER BY \"preset_field\" <=> '[0.5,0.6]' LIMIT 5"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(status: 'active').knn(
        target: 'embedding',
        vector: [0.1, 0.2],
        limit: 5
      ),
      "SELECT \"items\".* FROM \"items\" WHERE \"items\".\"status\" = 'active' " \
        "ORDER BY \"embedding\" <=> '[0.1,0.2]' LIMIT 5"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(project_id: [1, 2, 3]).knn(
        target: 'embedding',
        vector: [0.1, 0.2],
        limit: 5
      ),
      "SELECT \"items\".* FROM \"items\" WHERE \"items\".\"project_id\" IN (1, 2, 3) " \
        "ORDER BY \"embedding\" <=> '[0.1,0.2]' LIMIT 5"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.and(
        ActiveContext::Query.filter(status: 'active'),
        ActiveContext::Query.filter(category: 'product')
      ).knn(
        target: 'embedding',
        vector: [0.1, 0.2],
        limit: 5
      ),
      "SELECT \"items\".* FROM \"items\" WHERE \"items\".\"status\" = 'active' " \
        "AND \"items\".\"category\" = 'product' ORDER BY \"embedding\" <=> '[0.1,0.2]' LIMIT 5"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.and(
        ActiveContext::Query.filter(status: 'active'),
        ActiveContext::Query.prefix(name: 'test')
      ).knn(
        target: 'embedding',
        vector: [0.1, 0.2],
        limit: 5
      ),
      "SELECT \"items\".* FROM \"items\" WHERE \"items\".\"status\" = 'active' AND (\"name\" LIKE 'test%') " \
        "ORDER BY \"embedding\" <=> '[0.1,0.2]' LIMIT 5"
  end

  context 'with limit queries' do
    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.filter(status: 'active').limit(10),
      "SELECT subq.* FROM (SELECT \"items\".* FROM \"items\" WHERE \"items\".\"status\" = 'active') subq LIMIT 10"

    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.knn(
        target: 'embedding',
        vector: [0.1, 0.2],
        limit: 5
      ).limit(10),
      "SELECT subq.* FROM (SELECT \"items\".* FROM \"items\" " \
        "ORDER BY \"embedding\" <=> '[0.1,0.2]' LIMIT 5) subq LIMIT 10"
  end

  context 'with all queries' do
    it_behaves_like 'a SQL transformer',
      ActiveContext::Query.all,
      "SELECT \"items\".* FROM \"items\""
  end
end
