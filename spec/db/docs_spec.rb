# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Database Documentation' do
  context 'for each table' do
    # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/366834
    let(:database_base_models) { Gitlab::Database.database_base_models.select { |k, _| k != 'geo' } }

    let(:all_tables) do
      database_base_models.flat_map { |_, m| m.connection.tables }.sort.uniq
    end

    let(:metadata_required_fields) do
      %i(
        feature_categories
        table_name
      )
    end

    let(:metadata_allowed_fields) do
      metadata_required_fields + %i(
        classes
        description
        introduced_by_url
        milestone
      )
    end

    let(:metadata) do
      all_tables.each_with_object({}) do |table_name, hash|
        next unless File.exist?(table_metadata_file_path(table_name))

        hash[table_name] ||= load_table_metadata(table_name)
      end
    end

    let(:tables_without_metadata) do
      all_tables.reject { |t| metadata.has_key?(t) }
    end

    let(:tables_without_valid_metadata) do
      metadata.select { |_, t| t.has_key?(:error) }.keys
    end

    let(:tables_with_disallowed_fields) do
      metadata.select { |_, t| t.has_key?(:disallowed_fields) }.keys
    end

    let(:tables_with_missing_required_fields) do
      metadata.select { |_, t| t.has_key?(:missing_required_fields) }.keys
    end

    it 'has a metadata file' do
      expect(tables_without_metadata).to be_empty, multiline_error(
        'Missing metadata files',
        tables_without_metadata.map { |t| "  #{table_metadata_file(t)}" }
      )
    end

    it 'has a valid metadata file' do
      expect(tables_without_valid_metadata).to be_empty, table_metadata_errors(
        'Table metadata files with errors',
        :error,
        tables_without_valid_metadata
      )
    end

    it 'has a valid metadata file with allowed fields' do
      expect(tables_with_disallowed_fields).to be_empty, table_metadata_errors(
        'Table metadata files with disallowed fields',
        :disallowed_fields,
        tables_with_disallowed_fields
      )
    end

    it 'has a valid metadata file without missing fields' do
      expect(tables_with_missing_required_fields).to be_empty, table_metadata_errors(
        'Table metadata files with missing fields',
        :missing_required_fields,
        tables_with_missing_required_fields
      )
    end
  end

  private

  def table_metadata_file(table_name)
    File.join('db', 'docs', "#{table_name}.yml")
  end

  def table_metadata_file_path(table_name)
    Rails.root.join(table_metadata_file(table_name))
  end

  def load_table_metadata(table_name)
    result = {}
    begin
      result[:metadata] = YAML.safe_load(File.read(table_metadata_file_path(table_name))).deep_symbolize_keys

      disallowed_fields = (result[:metadata].keys - metadata_allowed_fields)
      unless disallowed_fields.empty?
        result[:disallowed_fields] = "fields not allowed: #{disallowed_fields.join(', ')}"
      end

      missing_required_fields = (metadata_required_fields - result[:metadata].reject { |_, v| v.blank? }.keys)
      unless missing_required_fields.empty?
        result[:missing_required_fields] = "missing required fields: #{missing_required_fields.join(', ')}"
      end
    rescue Psych::SyntaxError => ex
      result[:error] = ex.message
    end
    result
  end

  def table_metadata_errors(title, field, tables)
    lines = tables.map do |table_name|
      <<~EOM
        #{table_metadata_file(table_name)}
          #{metadata[table_name][field]}
      EOM
    end

    multiline_error(title, lines)
  end

  def multiline_error(title, lines)
    <<~EOM
      #{title}:

      #{lines.join("\n")}
    EOM
  end
end
