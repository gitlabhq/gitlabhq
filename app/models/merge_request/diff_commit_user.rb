# frozen_string_literal: true

class MergeRequest::DiffCommitUser < ApplicationRecord
  validates :name, length: { maximum: 512 }
  validates :email, length: { maximum: 512 }
  validates :name, presence: true, unless: :email
  validates :email, presence: true, unless: :name

  # Prepares a value to be inserted into a column in the table
  # `merge_request_diff_commit_users`. Values in this table are limited to
  # 512 characters.
  #
  # We treat empty strings as NULL values, as there's no point in (for
  # example) storing a row where both the name and Email are an empty
  # string. In addition, if we treated them differently we could end up with
  # two rows: one where field X is NULL, and one where field X is an empty
  # string. This is redundant, so we avoid storing such data.
  def self.prepare(value)
    value.present? ? value[0..511] : nil
  end

  # Creates a new row, or returns an existing one if a row already exists.
  def self.find_or_create(name, email, organization_id)
    find_or_create_by!(name: name, email: email, organization_id: organization_id)
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  # Finds many (name, email, organization_id) triples in bulk.
  def self.bulk_find(input)
    queries = {}
    rows = []

    input.each do |item|
      name, email, organization_id = item
      conditions = { name: name, email: email, organization_id: organization_id }
      queries[conditions.values] = where(conditions).to_sql
    end

    # We may end up having to query many users. To ensure we don't hit any
    # query size limits, we get a fixed number of users at a time.
    queries.values.each_slice(1_000).map do |slice|
      rows.concat(from("(#{slice.join("\nUNION ALL\n")}) #{table_name}").to_a)
    end

    rows
  end

  # Finds or creates rows for the given input.
  #
  # The input argument must be:
  # - Array/Set of triples like [[name, email, organization_id], ...]
  #
  # This method expects that the names and emails have already been trimmed to
  # at most 512 characters.
  #
  # The return value is a Hash that maps input to instances of this model.
  def self.bulk_find_or_create(input)
    mapping = {}

    # Find existing records with exact matches
    existing_records = bulk_find(input)

    existing_records.each do |row|
      # Map all found records with triples
      mapping[[row.name, row.email, row.organization_id]] = row
    end

    # Create missing records
    create_missing_records(input, mapping)

    # Handle concurrent inserts
    handle_concurrent_inserts(input, mapping)

    mapping
  end

  def self.create_missing_records(input, mapping)
    create = []

    # Collect records that need to be created
    input.each do |name, email, organization_id|
      next if mapping[[name, email, organization_id]]

      create << { name: name, email: email, organization_id: organization_id }
    end

    return if create.empty?

    # Bulk insert new records
    insert_all(create, returning: %w[id name email organization_id]).each do |row|
      # Use triples as keys
      mapping[[row['name'], row['email'], row['organization_id']]] =
        new(id: row['id'], name: row['name'], email: row['email'], organization_id: row['organization_id'])
    end
  end

  def self.handle_concurrent_inserts(input, mapping)
    # Find any records that were created concurrently
    missing_triples = input.reject { |item| mapping.key?(item) }
    return if missing_triples.empty?

    bulk_find(missing_triples).each do |row|
      mapping[[row.name, row.email, row.organization_id]] = row
    end
  end

  private_class_method :create_missing_records,
    :handle_concurrent_inserts
end
