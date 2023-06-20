# frozen_string_literal: true

class ValidateFkCiBuildReportResultsPCiBuilds < Gitlab::Database::Migration[2.1]
  def up
    validate_foreign_key :ci_build_report_results, nil, name: :temp_fk_rails_16cb1ff064_p
  end

  def down
    # no-op
  end
end
