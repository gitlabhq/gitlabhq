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
  def self.find_or_create(name, email)
    find_or_create_by!(name: name, email: email)
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  # Finds many (name, email) pairs in bulk.
  def self.bulk_find(pairs)
    queries = {}
    rows = []

    pairs.each do |(name, email)|
      queries[[name, email]] = where(name: name, email: email).to_sql
    end

    # We may end up having to query many users. To ensure we don't hit any
    # query size limits, we get a fixed number of users at a time.
    queries.values.each_slice(1_000).map do |slice|
      rows.concat(from("(#{slice.join("\nUNION ALL\n")}) #{table_name}").to_a)
    end

    rows
  end

  # Finds or creates rows for the given pairs of names and Emails.
  #
  # The `names_and_emails` argument must be an Array/Set of tuples like so:
  #
  #     [
  #       [name, email],
  #       [name, email],
  #       ...
  #     ]
  #
  # This method expects that the names and Emails have already been trimmed to
  # at most 512 characters.
  #
  # The return value is a Hash that maps these tuples to instances of this
  # model.
  def self.bulk_find_or_create(pairs)
    mapping = {}
    create = []

    # Over time, fewer new rows need to be created. We take advantage of that
    # here by first finding all rows that already exist, using a limited number
    # of queries (in most cases only one query will be needed).
    bulk_find(pairs).each do |row|
      mapping[[row.name, row.email]] = row
    end

    pairs.each do |(name, email)|
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
    bulk_find(pairs.reject { |pair| mapping.key?(pair) }).each do |row|
      mapping[[row.name, row.email]] = row
    end

    mapping
  end
end
