# frozen_string_literal: true

class ReplaceExternalWikiTriggers < ActiveRecord::Migration[6.1]
  include Gitlab::Database::SchemaHelpers

  def up
    replace_triggers('type_new', 'Integrations::ExternalWiki')

    # we need an extra trigger to handle when type_new is updated by the
    # `integrations_set_type_new` trigger.
    # This can be removed when this trigger has been removed.
    execute(<<~SQL.squish)
      CREATE TRIGGER #{trigger_name(:type_new_updated)}
        AFTER UPDATE OF type_new ON integrations FOR EACH ROW
        WHEN ((new.type_new)::text = 'Integrations::ExternalWiki'::text AND new.project_id IS NOT NULL)
        EXECUTE FUNCTION set_has_external_wiki();
    SQL
  end

  def down
    execute("DROP TRIGGER IF EXISTS #{trigger_name(:type_new_updated)} ON integrations;")
    replace_triggers('type', 'ExternalWikiService')
  end

  private

  def replace_triggers(column_name, value)
    triggers(column_name, value).each do |event, condition|
      trigger = trigger_name(event)

      # create duplicate trigger, using the defined condition
      execute(<<~SQL.squish)
      CREATE TRIGGER #{trigger}_new AFTER #{event.upcase} ON integrations FOR EACH ROW
        WHEN (#{condition})
        EXECUTE FUNCTION set_has_external_wiki();
      SQL

      # Swap the triggers in place, so that the new trigger has the canonical name
      execute("ALTER TRIGGER #{trigger} ON integrations RENAME TO #{trigger}_old;")
      execute("ALTER TRIGGER #{trigger}_new ON integrations RENAME TO #{trigger};")

      # remove the old, now redundant trigger
      execute("DROP TRIGGER IF EXISTS #{trigger}_old ON integrations;")
    end
  end

  def trigger_name(event)
    "trigger_has_external_wiki_on_#{event}"
  end

  def triggers(column_name, value)
    {
      delete: "#{matches_value('old', column_name, value)} AND #{project_not_null('old')}",
      insert: "(new.active = true) AND #{matches_value('new', column_name, value)} AND #{project_not_null('new')}",
      update: "#{matches_value('new', column_name, value)} AND (old.active <> new.active) AND #{project_not_null('new')}"
    }
  end

  def project_not_null(row)
    "(#{row}.project_id IS NOT NULL)"
  end

  def matches_value(row, column_name, value)
    "((#{row}.#{column_name})::text = '#{value}'::text)"
  end
end
