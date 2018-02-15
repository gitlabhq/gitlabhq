module EE
  module ProjectAuthorization
    extend ActiveSupport::Concern

    module ClassMethods
      def roles_stats
        connection.execute <<-EOF.strip_heredoc
          SELECT CASE max(access_level)
          WHEN 10 THEN 'guest'
          WHEN 20 THEN 'reporter'
          WHEN 30 THEN 'developer'
          WHEN 40 THEN 'master'
          WHEN 50 THEN 'owner'
          ELSE 'unknown' END
          AS kind,
            count(DISTINCT user_id) AS amount
          FROM #{table_name}
          GROUP BY access_level
          ORDER BY amount DESC;
        EOF
      end
    end
  end
end
