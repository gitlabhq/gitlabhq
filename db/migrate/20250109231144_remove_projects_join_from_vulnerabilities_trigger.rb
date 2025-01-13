# frozen_string_literal: true

class RemoveProjectsJoinFromVulnerabilitiesTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def up
    execute(<<~SQL)
    CREATE OR REPLACE FUNCTION insert_vulnerability_reads_from_vulnerability() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
    DECLARE
      scanner_id bigint;
      uuid uuid;
      location_image text;
      cluster_agent_id text;
      casted_cluster_agent_id bigint;
      has_issues boolean;
      has_merge_request boolean;
    BEGIN
      SELECT
        v_o.scanner_id, v_o.uuid, v_o.location->>'image', v_o.location->'kubernetes_resource'->>'agent_id', CAST(v_o.location->'kubernetes_resource'->>'agent_id' AS bigint)
      INTO
        scanner_id, uuid, location_image, cluster_agent_id, casted_cluster_agent_id
      FROM
        vulnerability_occurrences v_o
      WHERE
        v_o.vulnerability_id = NEW.id
      LIMIT 1;

      SELECT
        EXISTS (SELECT 1 FROM vulnerability_issue_links WHERE vulnerability_issue_links.vulnerability_id = NEW.id)
      INTO
        has_issues;

      SELECT
        EXISTS (SELECT 1 FROM vulnerability_merge_request_links WHERE vulnerability_merge_request_links.vulnerability_id = NEW.id)
      INTO
        has_merge_request;

      INSERT INTO vulnerability_reads (vulnerability_id, project_id, scanner_id, report_type, severity, state, resolved_on_default_branch, uuid, location_image, cluster_agent_id, casted_cluster_agent_id, has_issues, has_merge_request)
        VALUES (NEW.id, NEW.project_id, scanner_id, NEW.report_type, NEW.severity, NEW.state, NEW.resolved_on_default_branch, uuid::uuid, location_image, cluster_agent_id, casted_cluster_agent_id, has_issues, has_merge_request)
        ON CONFLICT(vulnerability_id) DO NOTHING;
      RETURN NULL;
    END
    $$
    SQL
  end

  def down
    execute(<<~SQL)
    CREATE OR REPLACE FUNCTION insert_vulnerability_reads_from_vulnerability() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
    DECLARE
      scanner_id bigint;
      uuid uuid;
      location_image text;
      cluster_agent_id text;
      casted_cluster_agent_id bigint;
      has_issues boolean;
      has_merge_request boolean;
    BEGIN
      SELECT
        v_o.scanner_id, v_o.uuid, v_o.location->>'image', v_o.location->'kubernetes_resource'->>'agent_id', CAST(v_o.location->'kubernetes_resource'->>'agent_id' AS bigint)
      INTO
        scanner_id, uuid, location_image, cluster_agent_id, casted_cluster_agent_id
      FROM
        vulnerability_occurrences v_o
      INNER JOIN projects ON projects.id = v_o.project_id
      WHERE
        v_o.vulnerability_id = NEW.id
      LIMIT 1;

      SELECT
        EXISTS (SELECT 1 FROM vulnerability_issue_links WHERE vulnerability_issue_links.vulnerability_id = NEW.id)
      INTO
        has_issues;

      SELECT
        EXISTS (SELECT 1 FROM vulnerability_merge_request_links WHERE vulnerability_merge_request_links.vulnerability_id = NEW.id)
      INTO
        has_merge_request;

      INSERT INTO vulnerability_reads (vulnerability_id, project_id, scanner_id, report_type, severity, state, resolved_on_default_branch, uuid, location_image, cluster_agent_id, casted_cluster_agent_id, has_issues, has_merge_request)
        VALUES (NEW.id, NEW.project_id, scanner_id, NEW.report_type, NEW.severity, NEW.state, NEW.resolved_on_default_branch, uuid::uuid, location_image, cluster_agent_id, casted_cluster_agent_id, has_issues, has_merge_request)
        ON CONFLICT(vulnerability_id) DO NOTHING;
      RETURN NULL;
    END
    $$
    SQL
  end
end
