# frozen_string_literal: true

# CustomUniquenessValidator
#
# Custom validator for unique values in the DB. Allows specifying custom SQL to compare existing values.
# Validator doesn't support uniqueness on associations as the default ActiveRecord uniqueness validator does.
#
# ActiveRecord's default uniqueness validator only supports uniqueness queries like the following:
#
# Case insensitive without scope:

# SELECT 1 AS one FROM "work_item_types" WHERE LOWER("work_item_types"."name") = LOWER('Test') LIMIT 1
#
# Case insensitive scoped:
#
# SELECT
#   1 AS one
# FROM
#   "work_item_widget_definitions"
# WHERE
#   LOWER(
#     "work_item_widget_definitions"."name"
#   ) = LOWER('different')
#   AND "work_item_widget_definitions"."work_item_type_id" = 5
# LIMIT
#   1

# With this validator you can replace parts of the query with custom sql. Examples:
#   class WorkItems::Type < ActiveRecord::Base
#     validates :name, custom_uniqueness: { unique_sql: 'TRIM(BOTH FROM lower(?))' }
#   end
#
# This will generate a query like:
#   SELECT
#   1 AS one
#   FROM "work_item_types" WHERE (TRIM(BOTH FROM lower(work_item_types.name)) = TRIM(BOTH FROM lower('Test'))) LIMIT 1
#
#
#   class WorkItems::WidgetDefinition < ActiveRecord::Base
#     validates :name, custom_uniqueness: { unique_sql: 'TRIM(BOTH FROM lower(?))', scope: :work_item_type_id }
#   end
# This will generate a query like:
#
#   SELECT
#   1 AS one
#   FROM
#     "work_item_widget_definitions"
#   WHERE
#     (
#       TRIM(
#         BOTH
#         FROM
#           lower(
#             work_item_widget_definitions.name
#           )
#       ) = TRIM(
#         BOTH
#         FROM
#           lower('test')
#       )
#     )
#     AND "work_item_widget_definitions"."work_item_type_id" = 5
#   LIMIT
#     1
#
# rubocop:disable CodeReuse/ActiveRecord -- Validator used in models
class CustomUniquenessValidator < ActiveModel::EachValidator # rubocop:disable Gitlab/BoundedContexts,Gitlab/NamespacedClass -- Validators can belong to multiple bounded contexts
  include ActiveRecord::ConnectionAdapters::Quoting
  include Gitlab::Utils::StrongMemoize

  def initialize(options)
    @unique_sql = options[:unique_sql]
    @scope_values = Array(options[:scope])
    @table_name = options[:class].table_name
    super
  end

  def validate_each(record, attribute, value)
    return unless validation_needed?(record, attribute) && record_exists?(record, attribute, value)

    record.errors.add(attribute, :taken)
  end

  def check_validity!
    super
    return unless unique_sql.blank?

    raise ArgumentError, '`unique_sql` option must be provided to the `custom_uniqueness` validator'
  end

  private

  attr_reader :unique_sql, :table_name, :scope_values

  def parsed_sql(attribute)
    strong_memoize_with(:parsed_sql, attribute) do
      "#{column_sql(attribute)} = #{unique_sql}"
    end
  end

  def column_sql(attribute)
    unique_sql.gsub('?', "#{quote_table_name(table_name)}.#{quote_column_name(attribute)}")
  end

  def record_exists?(record, attribute, value)
    relation = record.class.where(
      parsed_sql(attribute),
      value
    )
    relation = relation.where.not(record.class.primary_key => record.to_key.first) if record.persisted?

    scope_relation(record, relation).exists?
  end

  def scope_relation(record, relation)
    scope_values.each do |scope_item|
      scope_value = record.read_attribute(scope_item)
      relation = relation.where(scope_item => scope_value)
    end

    relation
  end

  def validation_needed?(record, attribute)
    attributes = scope_values + [attribute]

    attributes.any? { |attr| record.attribute_changed?(attr) || record.read_attribute(attr).nil? }
  end
end
# rubocop:enable CodeReuse/ActiveRecord
