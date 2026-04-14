# frozen_string_literal: true

RSpec.describe "data isolation SQL" do
  let(:organization_id) { 42 }

  before do
    Gitlab::Database::DataIsolation.configure do |c|
      c.current_sharding_key_value = ->(_sk) { organization_id }
    end
  end

  where do
    {
      "simple SELECT" => {
        query: -> { Project.all.to_sql },
        arel: 'SELECT "projects".* ' \
          'FROM "projects" ' \
          'WHERE "projects"."organization_id" = 42'
      },
      "unscoped table" => {
        query: -> { Feature.all.to_sql },
        arel: 'SELECT "features".* FROM "features"'
      },
      "INNER JOIN on issues" => {
        query: -> { Project.joins("INNER JOIN issues ON issues.project_id = projects.id").to_sql },
        arel: 'SELECT "projects".* ' \
          'FROM "projects" ' \
          'INNER JOIN issues ON issues.project_id = projects.id ' \
          'WHERE "projects"."organization_id" = 42'
      },
      "INNER JOIN on projects" => {
        query: -> { Issue.joins("INNER JOIN projects ON projects.id = issues.project_id").to_sql },
        arel: 'SELECT "issues".* ' \
          'FROM "issues" ' \
          'INNER JOIN projects ON projects.id = issues.project_id'
      },
      "WHERE IN subquery" => {
        query: -> { Project.where(id: Issue.select(:project_id)).to_sql },
        arel: 'SELECT "projects".* ' \
          'FROM "projects" ' \
          'WHERE "projects"."id" IN (SELECT "issues"."project_id" FROM "issues") ' \
          'AND "projects"."organization_id" = 42'
      },
      "CTE" => {
        query: -> { Project.with(recent_issues: Issue.select(:project_id)).to_sql },
        arel: 'WITH "recent_issues" AS (SELECT "issues"."project_id" FROM "issues") ' \
          'SELECT "projects".* ' \
          'FROM "projects" ' \
          'WHERE "projects"."organization_id" = 42'
      }
    }
  end

  with_them do
    it "applies :arel strategy" do
      ActiveRecord::Relation.prepend(Gitlab::Database::DataIsolation::Strategies::Arel::ActiveRecordExtension)
      Gitlab::Database::DataIsolation.configure { |c| c.strategy = :arel }
      expect(query.call).to eq(arel)
    end
  end
end
