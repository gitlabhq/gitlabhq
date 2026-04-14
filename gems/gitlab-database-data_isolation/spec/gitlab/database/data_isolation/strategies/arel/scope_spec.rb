# frozen_string_literal: true

RSpec.describe Gitlab::Database::DataIsolation::Strategies::Arel::Scope do
  let(:organization_id) { 1234 }
  let(:unmodified_sql) { ast.to_sql }

  subject(:scoped) { described_class.new(organization_id).add_scope(ast) }

  describe '.without_data_isolation (via Context)' do
    let(:ast) { Project.all.arel }

    it 'does not change the query' do
      Gitlab::Database::DataIsolation::Context.without_data_isolation do
        expect(scoped.to_sql).to eq(unmodified_sql)
      end
    end
  end

  context 'when the query is using a table not in sharding_key_map' do
    let(:ast) { Snippet.all.arel }

    it 'does nothing' do
      expect(scoped.to_sql).to eq(unmodified_sql)
    end
  end

  context 'when the query is using a table that has organization_id in sharding_key_map' do
    let(:ast) { Project.all.arel }
    let(:modified_sql) { "#{unmodified_sql} WHERE \"projects\".\"organization_id\" = #{organization_id}" }

    it 'adds the scope' do
      expect(scoped.to_sql).to eq(modified_sql)
    end
  end

  context 'when the query is using joins' do
    before do
      Project.has_many :issues, foreign_key: :project_id
    end

    context 'with INNER JOIN' do
      let(:ast) { Project.joins(:issues).arel }
      let(:modified_sql) { "#{unmodified_sql} WHERE \"projects\".\"organization_id\" = #{organization_id}" }

      it 'adds the scope only on the from table and not on the joined table' do
        expect(scoped.to_sql).to eq(modified_sql)
      end
    end

    context 'with LEFT OUTER JOIN' do
      let(:ast) { Project.left_outer_joins(:issues).arel }
      let(:modified_sql) { "#{unmodified_sql} WHERE \"projects\".\"organization_id\" = #{organization_id}" }

      it 'adds the scope only on the from table' do
        expect(scoped.to_sql).to eq(modified_sql)
      end
    end

    context 'with explicit Arel join on a scoped table' do
      let(:ast) do
        projects = Project.arel_table
        issues = Issue.arel_table
        Project.joins(projects.join(issues).on(issues[:project_id].eq(projects[:id])).join_sources).arel
      end

      let(:modified_sql) { "#{unmodified_sql} WHERE \"projects\".\"organization_id\" = #{organization_id}" }

      it 'adds the scope only on the from table' do
        expect(scoped.to_sql).to eq(modified_sql)
      end
    end

    context 'with join between scoped and unscoped table' do
      let(:ast) do
        projects = Project.arel_table
        user_details = UserDetail.arel_table
        Project.joins(
          projects.join(user_details).on(user_details[:user_id].eq(projects[:id])).join_sources
        ).arel
      end

      let(:modified_sql) { "#{unmodified_sql} WHERE \"projects\".\"organization_id\" = #{organization_id}" }

      it 'adds the scope only on the from table' do
        expect(scoped.to_sql).to eq(modified_sql)
      end
    end
  end

  context 'when the query uses a subquery in WHERE' do
    let(:ast) do
      subquery = Issue.select(:project_id).where(title: 'test').arel
      Project.where(Project.arel_table[:id].in(subquery)).arel
    end

    it 'scopes the outer FROM table without modifying the subquery' do
      expected = "#{unmodified_sql} AND \"projects\".\"organization_id\" = #{organization_id}"
      expect(scoped.to_sql).to eq(expected)
    end
  end

  context 'when the query uses a subquery in FROM (derived table)' do
    let(:inner_query) { Project.select(:id, :name).where(name: 'test').arel }
    let(:ast) do
      subquery_alias = Arel::Nodes::TableAlias.new(inner_query, 'derived')
      query = Arel::SelectManager.new
      query.from(subquery_alias)
      query.project(Arel.star)
      query
    end

    it 'does not scope the derived table alias' do
      expect(scoped.to_sql).to eq(unmodified_sql)
    end
  end

  context 'when the query uses a CTE' do
    let(:cte_table) { Arel::Table.new('project_cte') }
    let(:cte_query) { Project.where(name: 'test').arel }
    let(:ast) do
      cte = Arel::Nodes::As.new(cte_table, cte_query)
      query = Arel::SelectManager.new
      query.with(cte)
      query.from(cte_table)
      query.project(Arel.star)
      query
    end

    it 'does not scope the CTE reference in FROM since it is not a real table' do
      expect(scoped.to_sql).to eq(unmodified_sql)
    end
  end

  context 'when the query uses a CTE with the main query selecting from a real table' do
    let(:cte_table) { Arel::Table.new('recent_issues') }
    let(:cte_query) { Issue.where(title: 'test').arel }
    let(:ast) do
      cte = Arel::Nodes::As.new(cte_table, cte_query)
      query = Project.all.arel
      query.with(cte)
      query
    end

    it 'scopes the main FROM table without touching the CTE definition' do
      expected = "#{unmodified_sql} WHERE \"projects\".\"organization_id\" = #{organization_id}"
      expect(scoped.to_sql).to eq(expected)
    end
  end

  context 'when the query uses EXISTS subquery' do
    let(:ast) do
      issues = Issue.arel_table
      projects = Project.arel_table
      exists = Arel::Nodes::Exists.new(
        Issue.select(1).where(issues[:project_id].eq(projects[:id])).arel
      )
      Project.where(exists).arel
    end

    it 'adds the scope on the outer FROM table' do
      expected = "#{unmodified_sql} AND \"projects\".\"organization_id\" = #{organization_id}"
      expect(scoped.to_sql).to eq(expected)
    end
  end

  context 'when the query uses NOT IN subquery' do
    let(:ast) do
      subquery = Issue.select(:project_id).arel
      Project.where(Project.arel_table[:id].not_in(subquery)).arel
    end

    it 'scopes the outer FROM table without modifying the subquery' do
      expected = "#{unmodified_sql} AND \"projects\".\"organization_id\" = #{organization_id}"
      expect(scoped.to_sql).to eq(expected)
    end
  end

  context 'when the query uses UNION' do
    let(:query1) { Project.where(name: 'a').arel }
    let(:query2) { Project.where(name: 'b').arel }
    let(:ast) do
      union = query1.union(query2)
      manager = Arel::SelectManager.new
      manager.from(Arel::Nodes::TableAlias.new(union, 'projects'))
      manager.project(Arel.star)
      manager
    end

    it 'does not scope the UNION (treated as derived table)' do
      expect(scoped.to_sql).to eq(unmodified_sql)
    end
  end

  context 'when the query has WHERE conditions and uses a scoped table' do
    let(:ast) { Project.where(name: 'test').arel }
    let(:modified_sql) { "#{unmodified_sql} AND \"projects\".\"organization_id\" = #{organization_id}" }

    it 'appends the sharding key scope to existing WHERE conditions' do
      expect(scoped.to_sql).to eq(modified_sql)
    end
  end

  context 'when the query is selecting from a function' do
    let(:ast) do
      func = Arel::Nodes::NamedFunction.new('some_function', [])
      query = Arel::SelectManager.new
      query.from(func)
      query.project(Arel.star)
      query
    end

    it 'does nothing' do
      expect(scoped.to_sql).to eq(unmodified_sql)
    end
  end

  context 'when sharding_key_map is empty' do
    let(:ast) { Project.all.arel }

    before do
      Gitlab::Database::DataIsolation.configure do |config|
        config.sharding_key_map = {}
      end
    end

    it 'does nothing' do
      expect(scoped.to_sql).to eq(unmodified_sql)
    end
  end

  context 'when the override value is nil' do
    subject(:scoped) { described_class.new(nil).add_scope(ast) }

    let(:ast) { Project.all.arel }

    it 'does nothing' do
      expect(scoped.to_sql).to eq(unmodified_sql)
    end
  end

  context 'when the table has multiple sharding keys (nullable OR)' do
    let(:ast) { Gitlab::Database::DataIsolation::Context.without_data_isolation { Snippet.all.arel } }
    let(:project_id) { 5678 }
    let(:modified_sql) do
      "#{unmodified_sql} WHERE (\"snippets\".\"project_id\" = #{project_id} " \
        "OR \"snippets\".\"organization_id\" = #{organization_id})"
    end

    subject(:scoped) { described_class.new.add_scope(ast) }

    before do
      sharding_key_values = { projects: project_id, organizations: organization_id }
      Gitlab::Database::DataIsolation.configure do |config|
        config.current_sharding_key_value = ->(type) { sharding_key_values[type] }
        config.sharding_key_map = {
          'snippets' => { 'project_id' => :projects, 'organization_id' => :organizations }
        }
      end
    end

    it 'adds an OR condition across all sharding key columns' do
      expect(scoped.to_sql).to eq(modified_sql)
    end

    context 'when one key type resolves to nil' do
      let(:ast) { Gitlab::Database::DataIsolation::Context.without_data_isolation { Snippet.all.arel } }

      before do
        Gitlab::Database::DataIsolation.configure do |config|
          config.current_sharding_key_value = ->(type) { organization_id if type == :organizations }
          config.sharding_key_map = {
            'snippets' => { 'project_id' => :projects, 'organization_id' => :organizations }
          }
        end
      end

      subject(:scoped) { described_class.new.add_scope(ast) }

      it 'uses only the non-nil condition' do
        expect(scoped.to_sql).to eq(
          "SELECT \"snippets\".* FROM \"snippets\" WHERE \"snippets\".\"organization_id\" = #{organization_id}"
        )
      end
    end
  end

  context 'when different tables use different sharding key types' do
    let(:ast) { Project.all.arel }

    before do
      Gitlab::Database::DataIsolation.configure do |config|
        config.sharding_key_map = {
          'projects' => { 'organization_id' => :organizations },
          'issues' => { 'namespace_id' => :namespaces }
        }
      end
    end

    it 'uses the override value for the scoped table' do
      expect(scoped.to_sql).to eq(
        "SELECT \"projects\".* FROM \"projects\" WHERE \"projects\".\"organization_id\" = #{organization_id}"
      )
    end
  end

  context 'when the sharding key value is an Arel relation' do
    let(:ast) { Project.all.arel }
    let(:modified_sql) do
      "#{unmodified_sql} WHERE \"projects\".\"organization_id\" IN (SELECT \"organizations\".\"id\" " \
        "FROM \"organizations\" WHERE \"organizations\".\"id\" = $1 AND \"organizations\".\"status\" = $2)"
    end

    subject(:scoped) do
      described_class.new(Organization.select(:id).where(id: organization_id, status: :active)).add_scope(ast)
    end

    it 'adds the scope' do
      expect(scoped.to_sql).to eq(modified_sql)
    end
  end
end
