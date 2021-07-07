# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Migrates author and committer names and emails from
    # merge_request_diff_commits to two columns that point to
    # merge_request_diff_commit_users.
    #
    # rubocop: disable Metrics/ClassLength
    class MigrateMergeRequestDiffCommitUsers
      # The number of user rows in merge_request_diff_commit_users to get in a
      # single query.
      USER_ROWS_PER_QUERY = 1_000

      # The number of rows in merge_request_diff_commits to get in a single
      # query.
      COMMIT_ROWS_PER_QUERY = 10_000

      # The number of rows in merge_request_diff_commits to update in a single
      # query.
      #
      # Tests in staging revealed that increasing the number of updates per
      # query translates to a longer total runtime for a migration. For example,
      # given the same range of rows to migrate, 1000 updates per query required
      # a total of roughly 15 seconds. On the other hand, 5000 updates per query
      # required a total of roughly 25 seconds. For this reason, we use a value
      # of 1000 rows per update.
      UPDATES_PER_QUERY = 1_000

      # rubocop: disable Style/Documentation
      class MergeRequestDiffCommit < ActiveRecord::Base
        include FromUnion
        extend ::SuppressCompositePrimaryKeyWarning

        self.table_name = 'merge_request_diff_commits'

        # Yields each row to migrate in the given range.
        #
        # This method uses keyset pagination to ensure we don't retrieve
        # potentially tens of thousands (or even hundreds of thousands) of rows
        # in a single query. Such queries could time out, or increase the amount
        # of memory needed to process the data.
        #
        # We can't use `EachBatch` and similar approaches, as
        # merge_request_diff_commits doesn't have a single monotonically
        # increasing primary key.
        def self.each_row_to_migrate(start_id, stop_id, &block)
          order = Pagination::Keyset::Order.build(
            %w[merge_request_diff_id relative_order].map do |col|
              Pagination::Keyset::ColumnOrderDefinition.new(
                attribute_name: col,
                order_expression: self.arel_table[col.to_sym].asc,
                nullable: :not_nullable,
                distinct: false
              )
            end
          )

          scope = MergeRequestDiffCommit
            .where(merge_request_diff_id: start_id...stop_id)
            .order(order)

          Pagination::Keyset::Iterator
            .new(scope: scope, use_union_optimization: true)
            .each_batch(of: COMMIT_ROWS_PER_QUERY) { |rows| rows.each(&block) }
        end
      end
      # rubocop: enable Style/Documentation

      # rubocop: disable Style/Documentation
      class MergeRequestDiffCommitUser < ActiveRecord::Base
        self.table_name = 'merge_request_diff_commit_users'

        def self.union(queries)
          from("(#{queries.join("\nUNION ALL\n")}) #{table_name}")
        end
      end
      # rubocop: enable Style/Documentation

      def perform(start_id, stop_id)
        # This Hash maps user names + emails to their corresponding rows in
        # merge_request_diff_commit_users.
        user_mapping = {}

        user_details, diff_rows_to_update = get_data_to_update(start_id, stop_id)

        get_user_rows_in_batches(user_details, user_mapping)
        create_missing_users(user_details, user_mapping)
        update_commit_rows(diff_rows_to_update, user_mapping)

        Database::BackgroundMigrationJob.mark_all_as_succeeded(
          'MigrateMergeRequestDiffCommitUsers',
          [start_id, stop_id]
        )
      end

      # Returns the data we'll use to determine what merge_request_diff_commits
      # rows to update, and what data to use for populating their
      # commit_author_id and committer_id columns.
      def get_data_to_update(start_id, stop_id)
        # This Set is used to retrieve users that already exist in
        # merge_request_diff_commit_users.
        users = Set.new

        # This Hash maps the primary key of every row in
        # merge_request_diff_commits to the (trimmed) author and committer
        # details to use for updating the row.
        to_update = {}

        MergeRequestDiffCommit.each_row_to_migrate(start_id, stop_id) do |row|
          author = [prepare(row.author_name), prepare(row.author_email)]
          committer = [prepare(row.committer_name), prepare(row.committer_email)]

          to_update[[row.merge_request_diff_id, row.relative_order]] =
            [author, committer]

          users << author if author[0] || author[1]
          users << committer if committer[0] || committer[1]
        end

        [users, to_update]
      end

      # Gets any existing rows in merge_request_diff_commit_users in batches.
      #
      # This method may end up having to retrieve lots of rows. To reduce the
      # overhead, we batch queries into a UNION query. We limit the number of
      # queries per UNION so we don't end up sending a single query containing
      # too many SELECT statements.
      def get_user_rows_in_batches(users, user_mapping)
        users.each_slice(USER_ROWS_PER_QUERY) do |pairs|
          queries = pairs.map do |(name, email)|
            MergeRequestDiffCommitUser.where(name: name, email: email).to_sql
          end

          MergeRequestDiffCommitUser.union(queries).each do |row|
            user_mapping[[row.name.to_s, row.email.to_s]] = row
          end
        end
      end

      # Creates any users for which no row exists in
      # merge_request_diff_commit_users.
      #
      # Not all users queried may exist yet, so we need to create any missing
      # ones; making sure we handle concurrent creations of the same user
      def create_missing_users(users, mapping)
        create = []

        users.each do |(name, email)|
          create << { name: name, email: email } unless mapping[[name, email]]
        end

        return if create.empty?

        MergeRequestDiffCommitUser
          .insert_all(create, returning: %w[id name email])
          .each do |row|
            mapping[[row['name'], row['email']]] = MergeRequestDiffCommitUser
              .new(id: row['id'], name: row['name'], email: row['email'])
          end

        # It's possible for (name, email) pairs to be inserted concurrently,
        # resulting in the above insert not returning anything. Here we get any
        # remaining users that were created concurrently.
        get_user_rows_in_batches(
          users.reject { |pair| mapping.key?(pair) },
          mapping
        )
      end

      # Updates rows in merge_request_diff_commits with their new
      # commit_author_id and committer_id values.
      def update_commit_rows(to_update, user_mapping)
        MergeRequestDiffCommitUser.transaction do
          to_update.each_slice(UPDATES_PER_QUERY) do |slice|
            updates = {}

            slice.each do |(diff_id, order), (author, committer)|
              author_id = user_mapping[author]&.id
              committer_id = user_mapping[committer]&.id

              updates[[diff_id, order]] = [author_id, committer_id]
            end

            bulk_update_commit_rows(updates)
          end
        end
      end

      # Bulk updates rows in the merge_request_diff_commits table with their new
      # author and/or committer ID values.
      #
      # Updates are batched together to reduce the overhead of having to produce
      # a single UPDATE for every row, as we may end up having to update
      # thousands of rows at once.
      #
      # The query produced by this method is along the lines of the following:
      #
      #     UPDATE merge_request_diff_commits
      #     SET commit_author_id =
      #       CASE
      #       WHEN (merge_request_diff_id, relative_order) = (x, y) THEN X
      #       WHEN ...
      #       END,
      #     committer_id =
      #       CASE
      #       WHEN (merge_request_diff_id, relative_order) = (x, y) THEN Y
      #       WHEN ...
      #       END
      #     WHERE (merge_request_diff_id, relative_order) IN ( (x, y), ... )
      #
      # The `mapping` argument is a Hash in the following format:
      #
      #     { [merge_request_diff_id, relative_order] => [author_id, committer_id] }
      #
      # rubocop: disable Metrics/AbcSize
      def bulk_update_commit_rows(mapping)
        author_case = Arel::Nodes::Case.new
        committer_case = Arel::Nodes::Case.new
        primary_values = []

        mapping.each do |diff_id_and_order, (author_id, committer_id)|
          primary_value = Arel::Nodes::Grouping.new(diff_id_and_order)

          primary_values << primary_value

          if author_id
            author_case.when(primary_key.eq(primary_value)).then(author_id)
          end

          if committer_id
            committer_case.when(primary_key.eq(primary_value)).then(committer_id)
          end
        end

        if author_case.conditions.empty? && committer_case.conditions.empty?
          return
        end

        fields = []

        # Statements such as `SET x = CASE END` are not valid SQL statements, so
        # we omit setting an ID field if there are no values to populate it
        # with.
        if author_case.conditions.any?
          fields << [arel_table[:commit_author_id], author_case]
        end

        if committer_case.conditions.any?
          fields << [arel_table[:committer_id], committer_case]
        end

        query = Arel::UpdateManager.new
          .table(arel_table)
          .where(primary_key.in(primary_values))
          .set(fields)
          .to_sql

        MergeRequestDiffCommit.connection.execute(query)
      end
      # rubocop: enable Metrics/AbcSize

      def primary_key
        Arel::Nodes::Grouping.new(
          [arel_table[:merge_request_diff_id], arel_table[:relative_order]]
        )
      end

      def arel_table
        MergeRequestDiffCommit.arel_table
      end

      # Prepares a value to be inserted into a column in the table
      # `merge_request_diff_commit_users`. Values in this table are limited to
      # 512 characters.
      #
      # We treat empty strings as NULL values, as there's no point in (for
      # example) storing a row where both the name and Email are an empty
      # string. In addition, if we treated them differently we could end up with
      # two rows: one where field X is NULL, and one where field X is an empty
      # string. This is redundant, so we avoid storing such data.
      def prepare(value)
        value.present? ? value[0..511] : nil
      end
    end
    # rubocop: enable Metrics/ClassLength
  end
end
