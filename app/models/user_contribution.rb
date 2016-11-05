class UserContribution < ActiveRecord::Base
  belongs_to :user

  def self.calculate_for(date)
    columns = %w(user_id date contributions).map { |column| connection.quote_column_name(column) }

    UserContribution.connection.execute <<-EOF
      INSERT INTO user_contributions (#{columns.join(', ')})
      SELECT author_id, #{connection.quote(date)}, COUNT(*) AS contributions
      FROM events
      WHERE created_at >= #{connection.quote(date.beginning_of_day)}
      AND created_at <= #{connection.quote(date.end_of_day)}
      AND author_id IS NOT NULL
      AND (
        (
          target_type in ('MergeRequest', 'Issue')
          AND action in (
            #{Event::CREATED},
            #{Event::CLOSED},
            #{Event::MERGED}
          )
        )
        OR (target_type = 'Note' AND action = #{Event::COMMENTED})
        OR action = #{Event::PUSHED}
      )
      GROUP BY author_id
    EOF
  rescue ActiveRecord::RecordNotUnique
    # If we violated the unique constraint, then we've already inserted this
    # day's rows.
  end
end
