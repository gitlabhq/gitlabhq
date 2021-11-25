# frozen_string_literal: true

class MakeIterationCadencesStartDateNullable < Gitlab::Database::Migration[1.0]
  def change
    change_column_null :iterations_cadences, :start_date, true
  end
end
