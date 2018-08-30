module EE
  module ProjectAuthorization
    extend ActiveSupport::Concern

    class_methods do
      # Get amout of users with highest role they have.
      # If John is developer in one project but maintainer in another he will be
      # counted once as maintainer. This is needed to count users who don't use
      # functionality available to higher roles only.
      #
      # Example of result:
      #  [{"kind"=>"guest", "amount"=>"4"},
      #  {"kind"=>"reporter", "amount"=>"6"},
      #  {"kind"=>"developer", "amount"=>"10"},
      #  {"kind"=>"maintainer", "amount"=>"9"},
      #  {"kind"=>"owner", "amount"=>"1"}]
      #
      def roles_stats
        connection.exec_query <<-EOF.strip_heredoc
          SELECT CASE access_level
            WHEN 10 THEN 'guest'
            WHEN 20 THEN 'reporter'
            WHEN 30 THEN 'developer'
            WHEN 40 THEN 'maintainer'
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
