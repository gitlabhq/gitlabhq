# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'validate dictionary' do |objects, directory_path, required_fields|
  context 'for each object' do
    let(:directory_path) {  directory_path }

    let(:metadata_allowed_fields) do
      required_fields + %i[
        feature_categories
        classes
        description
        introduced_by_url
        milestone
        gitlab_schema
        schema_inconsistencies
        sharding_key
        desired_sharding_key
        allow_cross_joins
        allow_cross_transactions
        allow_cross_foreign_keys
        desired_sharding_key_migration_job_name
        exempt_from_sharding
        sharding_key_issue_url
        notes
        table_size
      ]
    end

    let(:metadata) do
      objects.each_with_object({}) do |object_name, hash|
        next unless File.exist?(object_metadata_file_path(object_name))

        hash[object_name] ||= load_object_metadata(required_fields, object_name)
      end
    end

    # This list is used to provide temporary exceptions for feature categories
    # that are transitioning and not yet in the feature_categories.yml file
    # any additions here should be accompanied by a link to an issue link
    let(:valid_feature_categories) do
      [
        'jihu' # https://gitlab.com/gitlab-org/database-team/team-tasks/-/issues/192
      ]
    end

    let(:all_feature_categories) do
      YAML.load_file(Rails.root.join('config/feature_categories.yml')) + valid_feature_categories
    end

    let(:objects_without_metadata) do
      objects.reject { |t| metadata.has_key?(t) }
    end

    let(:objects_without_valid_metadata) do
      metadata.select { |_, t| t.has_key?(:error) }.keys
    end

    let(:objects_with_disallowed_fields) do
      metadata.select { |_, t| t.has_key?(:disallowed_fields) }.keys
    end

    let(:objects_with_missing_required_fields) do
      metadata.select { |_, t| t.has_key?(:missing_required_fields) }.keys
    end

    let(:objects_with_invalid_feature_category) do
      metadata.select { |_, t| t.has_key?(:invalid_feature_category) }.keys
    end

    it 'has a metadata file' do
      expect(objects_without_metadata).to be_empty, multiline_error(
        'Missing metadata files',
        objects_without_metadata.map { |t| "  #{object_metadata_file(t)}" }
      )
    end

    it 'has a valid metadata file' do
      expect(objects_without_valid_metadata).to be_empty, object_metadata_errors(
        'Table metadata files with errors',
        :error,
        objects_without_valid_metadata
      )
    end

    it 'has a valid feature category' do
      message = <<~TEXT.chomp
        Please use a category from https://about.gitlab.com/handbook/product/categories/#categories-a-z

        Table metadata files with an invalid feature category
      TEXT

      expect(objects_with_invalid_feature_category).to be_empty, object_metadata_errors(
        message,
        :invalid_feature_category,
        objects_with_invalid_feature_category
      )
    end

    it 'has a valid metadata file with allowed fields' do
      expect(objects_with_disallowed_fields).to be_empty, object_metadata_errors(
        'Table metadata files with disallowed fields',
        :disallowed_fields,
        objects_with_disallowed_fields
      )
    end

    it 'has a valid metadata file without missing fields' do
      expect(objects_with_missing_required_fields).to be_empty, object_metadata_errors(
        'Table metadata files with missing fields',
        :missing_required_fields,
        objects_with_missing_required_fields
      )
    end
  end

  private

  def object_metadata_file(object_name)
    File.join(directory_path, "#{object_name}.yml")
  end

  def object_metadata_file_path(object_name)
    Rails.root.join(object_metadata_file(object_name))
  end

  def invalid_feature_categories(object_feature_categories)
    return [] unless object_feature_categories.present?

    object_feature_categories - all_feature_categories
  end

  def load_object_metadata(required_fields, object_name)
    result = {}
    begin
      result[:metadata] = YAML.safe_load(File.read(object_metadata_file_path(object_name))).deep_symbolize_keys

      disallowed_fields = (result[:metadata].keys - metadata_allowed_fields)
      result[:disallowed_fields] = "fields not allowed: #{disallowed_fields.join(', ')}" unless disallowed_fields.empty?

      missing_required_fields = (required_fields - result[:metadata].reject { |_, v| v.blank? }.keys)
      unless missing_required_fields.empty?
        result[:missing_required_fields] = "missing required fields: #{missing_required_fields.join(', ')}"
      end

      if required_fields.include?(:feature_categories)
        object_feature_categories = result.dig(:metadata, :feature_categories)

        if (invalid = invalid_feature_categories(object_feature_categories)).any?
          result[:invalid_feature_category] = "invalid feature category: #{invalid.join(', ')}"
        end
      end
    rescue Psych::SyntaxError => ex
      result[:error] = ex.message
    end
    result
  end

  # rubocop:disable Naming/HeredocDelimiterNaming
  def object_metadata_errors(title, field, objects)
    lines = objects.map do |object_name|
      <<~EOM
        #{object_metadata_file(object_name)}
          #{metadata[object_name][field]}
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
  # rubocop:enable Naming/HeredocDelimiterNaming
end

RSpec.describe 'Views documentation', feature_category: :database do
  excluded = %w[geo jh]
  database_base_models = Gitlab::Database.database_base_models.reject { |k, _| k.in?(excluded) }
  views = database_base_models.flat_map { |_, m| m.connection.views }.sort.uniq
  directory_path = File.join('db', 'docs', 'views')
  required_fields = %i[feature_categories view_name gitlab_schema]

  include_examples 'validate dictionary', views, directory_path, required_fields
end

RSpec.describe 'Tables documentation', feature_category: :database do
  excluded = %w[geo jh]
  database_base_models = Gitlab::Database.database_base_models.reject { |k, _| k.in?(excluded) }
  tables = database_base_models.flat_map { |_, m| m.connection.tables }.sort.uniq
  directory_path = File.join('db', 'docs')
  required_fields = %i[feature_categories table_name gitlab_schema milestone]

  include_examples 'validate dictionary', tables, directory_path, required_fields
end

RSpec.describe 'Deleted tables documentation', feature_category: :database do
  directory_path = File.join('db', 'docs', 'deleted_tables')
  tables = Dir.glob(File.join(directory_path, '*.yml')).map { |f| File.basename(f, '.yml') }.sort.uniq
  required_fields = %i[table_name gitlab_schema removed_by_url removed_in_milestone]

  include_examples 'validate dictionary', tables, directory_path, required_fields
end

RSpec.describe 'Deleted views documentation', feature_category: :database do
  directory_path = File.join('db', 'docs', 'deleted_views')
  views = Dir.glob(File.join(directory_path, '*.yml')).map { |f| File.basename(f, '.yml') }.sort.uniq
  required_fields = %i[view_name gitlab_schema removed_by_url removed_in_milestone]

  include_examples 'validate dictionary', views, directory_path, required_fields
end
