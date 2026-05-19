# frozen_string_literal: true

class BackfillLanguageIdOnProgrammingLanguages < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_local

  def up
    yaml_path = Rails.root.join("vendor/languages.yml")
    return unless File.exist?(yaml_path)

    mapping = begin
      YAML.safe_load_file(yaml_path)
    rescue Psych::SyntaxError
      nil
    end

    return unless mapping.is_a?(Hash)

    model = define_batchable_model('programming_languages')

    model.where(language_id: nil).pluck(:id, :name).each do |id, name|
      language_id = mapping.dig(name, 'language_id')
      next unless language_id

      model.where(id: id).update_all(language_id: language_id)
    end
  end

  def down
    # no-op
  end
end
