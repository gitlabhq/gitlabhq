# frozen_string_literal: true

module CustomerRelations
  class GroupMigrationService
    def initialize(old_group_id, new_group_id, was_crm_source)
      @old_group_id = old_group_id
      @new_group_id = new_group_id
      @was_crm_source = was_crm_source
    end

    def execute
      copy_organizations
      copy_contacts
      update_issues

      return unless @was_crm_source

      old_group = Group.find_by_id(@old_group_id)
      old_group.delete_contacts
      old_group.delete_organizations
    end

    private

    def execute_sql(sql, args)
      sanitized_sql = ApplicationRecord.sanitize_sql([sql, args])
      ApplicationRecord.connection.execute(sanitized_sql, args)
    end

    def copy_organizations
      sql = <<~SQL
        -- Insert organizations deduplicating by name
        INSERT INTO #{CustomerRelations::Organization.table_name} (
          group_id,
          created_at,
          updated_at,
          state,
          default_rate,
          name,
          description
        )
        SELECT
          :new_group_id,
          source_organizations.created_at,
          source_organizations.updated_at,
          source_organizations.state,
          source_organizations.default_rate,
          source_organizations.name,
          source_organizations.description
        FROM #{CustomerRelations::Organization.table_name} source_organizations
        LEFT JOIN #{CustomerRelations::Organization.table_name} target_organizations
        ON target_organizations.group_id = :new_group_id AND LOWER(target_organizations.name) = LOWER(source_organizations.name)
        WHERE source_organizations.group_id = :old_group_id AND target_organizations.id IS NULL
      SQL
      execute_sql(sql, { old_group_id: @old_group_id, new_group_id: @new_group_id })
    end

    def copy_contacts
      sql = <<~SQL
        WITH org_map AS (
          -- Create a mapping of old organization IDs to new organization IDs
          SELECT source_organizations.id AS old_id, target_organizations.id AS new_id
          FROM #{CustomerRelations::Organization.table_name} source_organizations
          JOIN #{CustomerRelations::Organization.table_name} target_organizations ON target_organizations.group_id = :new_group_id AND LOWER(target_organizations.name) = LOWER(source_organizations.name)
          WHERE source_organizations.group_id = :old_group_id
        )
        -- Insert contacts linked to the new organization, deduplicating by email
        INSERT INTO #{CustomerRelations::Contact.table_name} (
          group_id,
          organization_id,
          created_at,
          updated_at,
          state,
          phone,
          first_name,
          last_name,
          email,
          description
        )
        SELECT DISTINCT
          :new_group_id,
          org_map.new_id,
          source_contacts.created_at,
          source_contacts.updated_at,
          source_contacts.state,
          source_contacts.phone,
          source_contacts.first_name,
          source_contacts.last_name,
          source_contacts.email,
          source_contacts.description
        FROM #{CustomerRelations::Contact.table_name} source_contacts
        LEFT JOIN #{CustomerRelations::Contact.table_name} target_contacts
        ON target_contacts.group_id = :new_group_id AND LOWER(target_contacts.email) = LOWER(source_contacts.email)
        LEFT JOIN org_map ON org_map.old_id = source_contacts.organization_id
        WHERE source_contacts.group_id = :old_group_id AND target_contacts.id IS NULL
      SQL
      execute_sql(sql, { old_group_id: @old_group_id, new_group_id: @new_group_id })
    end

    def update_issues
      sql = <<~SQL
        UPDATE #{CustomerRelations::IssueContact.table_name}
        SET contact_id = target_contacts.id
        FROM #{CustomerRelations::Contact.table_name} AS source_contacts
        JOIN #{CustomerRelations::Contact.table_name} AS target_contacts ON target_contacts.group_id = :new_group_id AND LOWER(target_contacts.email) = LOWER(source_contacts.email)
        WHERE source_contacts.group_id = :old_group_id AND contact_id = source_contacts.id
      SQL
      execute_sql(sql, { old_group_id: @old_group_id, new_group_id: @new_group_id })
    end
  end
end
