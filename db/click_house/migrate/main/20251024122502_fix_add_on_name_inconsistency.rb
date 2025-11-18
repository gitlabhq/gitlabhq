# frozen_string_literal: true

class FixAddOnNameInconsistency < ClickHouse::Migration
  def up
    # Update numeric add_on_name values to their string equivalents
    # Mapping based on GitlabSubscriptions::AddOn enum:
    # 1 => code_suggestions, 2 => product_analytics, 3 => duo_enterprise
    # 4 => duo_amazon_q, 5 => duo_core, 6 => duo_self_hosted
    execute <<~SQL
      ALTER TABLE user_add_on_assignments_history UPDATE
        add_on_name = CASE add_on_name
          WHEN '1' THEN 'code_suggestions'
          WHEN '2' THEN 'product_analytics'
          WHEN '3' THEN 'duo_enterprise'
          WHEN '4' THEN 'duo_amazon_q'
          WHEN '5' THEN 'duo_core'
          WHEN '6' THEN 'duo_self_hosted'
          ELSE add_on_name
        END
      WHERE add_on_name IN ('1', '2', '3', '4', '5', '6')
    SQL
  end

  def down
    # no-op
  end
end
