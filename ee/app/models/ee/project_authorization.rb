module EE
  module ProjectAuthorization
    extend ActiveSupport::Concern

    module ClassMethods
      def roles_stats
        connection.execute <<-EOF.strip_heredoc
          SELECT CASE access_level
            WHEN 10 THEN 'guest'
            WHEN 20 THEN 'reporter'
            WHEN 30 THEN 'developer'
            WHEN 40 THEN 'master'
            WHEN 50 THEN 'owner'
            ELSE 'unknown' END
            AS kind,
            count(*) AS amount
          FROM (
              SELECT user_id, max(access_level) AS access_level
              FROM #{table_name}
              GROUP BY user_id
          ) access_per_user
          GROUP BY access_level
          ORDER BY access_level ASC;
        EOF
      end
    end
  end
end
