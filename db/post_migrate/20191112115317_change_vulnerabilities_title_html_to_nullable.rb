# frozen_string_literal: true

class ChangeVulnerabilitiesTitleHtmlToNullable < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    change_column_null :vulnerabilities, :title_html, true
  end
end
