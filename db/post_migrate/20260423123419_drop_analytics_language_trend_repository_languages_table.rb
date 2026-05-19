# frozen_string_literal: true

class DropAnalyticsLanguageTrendRepositoryLanguagesTable < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    drop_table :analytics_language_trend_repository_languages
  end

  def down
    execute(<<~SQL)
      CREATE TABLE analytics_language_trend_repository_languages (
        file_count integer DEFAULT 0 NOT NULL,
        programming_language_id bigint NOT NULL,
        project_id bigint NOT NULL,
        loc integer DEFAULT 0 NOT NULL,
        bytes integer DEFAULT 0 NOT NULL,
        percentage smallint DEFAULT 0 NOT NULL,
        snapshot_date date NOT NULL
      );

      ALTER TABLE ONLY analytics_language_trend_repository_languages
        ADD CONSTRAINT analytics_language_trend_repository_languages_pkey PRIMARY KEY (programming_language_id, project_id, snapshot_date);

      CREATE INDEX analytics_repository_languages_on_project_id ON analytics_language_trend_repository_languages USING btree (project_id);

      ALTER TABLE ONLY analytics_language_trend_repository_languages
        ADD CONSTRAINT fk_rails_86cc9aef5f FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;

      ALTER TABLE ONLY analytics_language_trend_repository_languages
        ADD CONSTRAINT fk_rails_9d851d566c FOREIGN KEY (programming_language_id) REFERENCES programming_languages(id) ON DELETE CASCADE;
    SQL
  end
end
