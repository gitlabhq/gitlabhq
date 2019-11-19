# frozen_string_literal: true

class AddCachedMarkdownVersionToVulnerabilities < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :vulnerabilities, :cached_markdown_version, :integer
  end
end
