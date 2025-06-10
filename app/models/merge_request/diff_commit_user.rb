# frozen_string_literal: true

class MergeRequest::DiffCommitUser < ApplicationRecord
  include SafelyChangeColumnDefault

  columns_changing_default :organization_id

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
  def self.find_or_create(name, email, organization_id, with_organization: false)
    return find_or_create_by!(name: name, email: email) unless with_organization

    # Try to find exact match first
    result = find_by(name: name, email: email, organization_id: organization_id)

    # If not found, look for one with nil organization_id
    if !result && organization_id.present?
      result = find_by(name: name, email: email, organization_id: nil)
      result.update!(organization_id: organization_id) if result
    end

    # If still not found, try to create using find_or_create_by!
    result || find_or_create_by!(name: name, email: email, organization_id: organization_id)
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  # Finds many (name, email) pairs or (name, email, organization_id) triples in bulk.
  def self.bulk_find(input, with_organization: false)
    queries = {}
    rows = []

    input.each do |item|
      name, email, organization_id = item
      conditions = { name: name, email: email }
      conditions[:organization_id] = organization_id if with_organization

      queries[conditions.values] = where(conditions).to_sql
    end

    # We may end up having to query many users. To ensure we don't hit any
    # query size limits, we get a fixed number of users at a time.
    queries.values.each_slice(1_000).map do |slice|
      rows.concat(from("(#{slice.join("\nUNION ALL\n")}) #{table_name}").to_a)
    end

    rows
  end

  # Finds or creates rows for the given pairs of names and Emails or
  # triples of names, emails, and organization IDs.
  #
  # The input argument must be an Array/Set of pairs or triples like so:
  #
  #     [
  #       [name, email],                   # legacy format when with_organization: false
  #       [name, email, organization_id],  # new format when with_organization: true
  #       ...
  #     ]
  #
  # This method expects that the names and emails have already been trimmed to
  # at most 512 characters.
  #
  # The return value is a Hash that maps these pairs/triples to instances of this model.
  def self.bulk_find_or_create(input, with_organization: false)
    return bulk_find_or_create_legacy(input) unless with_organization

    mapping = {}
    ids_to_update = []

    # Extract organization_id - it's the same for all triples in this batch
    organization_id = input.first&.last

    # Find all existing records by (name, email) only
    existing_records = bulk_find(input, with_organization: false)

    existing_records.each do |row|
      ids_to_update << row.id if row.organization_id.nil?
      # Map all found records with the organization_id from input
      mapping[[row.name, row.email, organization_id]] = row
    end

    # Bulk update organization_ids for records that had nil
    if ids_to_update.any?
      where(id: ids_to_update).update_all(organization_id: organization_id)

      # Update the organization_id on the objects we already have
      existing_records.each do |row|
        row.organization_id = organization_id if ids_to_update.include?(row.id)
      end
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
    input.each do |(name, email, org_id)|
      next if mapping[[name, email, org_id]]

      create << { name: name, email: email, organization_id: org_id }
    end

    return if create.empty?

    # Bulk insert new records
    insert_all(create, returning: %w[id name email organization_id]).each do |row|
      mapping[[row['name'], row['email'], row['organization_id']]] =
        new(id: row['id'], name: row['name'], email: row['email'], organization_id: row['organization_id'])
    end
  end

  def self.handle_concurrent_inserts(input, mapping)
    # Find any records that were created concurrently
    missing_triples = input.reject { |(name, email, org_id)| mapping.key?([name, email, org_id]) }

    return if missing_triples.empty?

    bulk_find(missing_triples, with_organization: true).each do |row|
      mapping[[row.name, row.email, row.organization_id]] = row
    end
  end

  def self.bulk_find_or_create_legacy(input)
    mapping = {}
    create = []

    # Over time, fewer new rows need to be created. We take advantage of that
    # here by first finding all rows that already exist, using a limited number
    # of queries (in most cases only one query will be needed).
    bulk_find(input).each do |row|
      mapping[[row.name, row.email]] = row
    end

    input.each do |(name, email)|
      create << { name: name, email: email } unless mapping[[name, email]]
    end

    return mapping if create.empty?

    # Sometimes we may need to insert new users into the table. We do this in
    # bulk, so we only need one INSERT for all missing users.
    insert_all(create, returning: %w[id name email]).each do |row|
      mapping[[row['name'], row['email']]] =
        new(id: row['id'], name: row['name'], email: row['email'])
    end

    # It's possible for (name, email) pairs to be inserted concurrently,
    # resulting in the above insert not returning anything. Here we get any
    # remaining users that were created concurrently.
    bulk_find(input.reject { |pair| mapping.key?(pair) }).each do |row|
      mapping[[row.name, row.email]] = row
    end

    mapping
  end

  private_class_method :bulk_find_or_create_legacy,
    :create_missing_records,
    :handle_concurrent_inserts
end
