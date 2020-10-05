# frozen_string_literal: true
require 'yaml'

class UpdateProgrammingLanguageColors < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  class ProgrammingLanguage < ActiveRecord::Base; end

  def up
    YAML.load_file("vendor/languages.yml").each do |name, metadata|
      color = metadata["color"]
      next unless color.present?

      ProgrammingLanguage.where(name: name).update(color: color)
    end
  end

  def down
    # noop
  end
end
