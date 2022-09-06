# frozen_string_literal: true

class AddDeletedOnToMlExperiments < Gitlab::Database::Migration[2.0]
  def change
    add_column :ml_experiments, :deleted_on, :datetime_with_timezone, index: true
  end
end
