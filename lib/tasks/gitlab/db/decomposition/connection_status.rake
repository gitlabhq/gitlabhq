# frozen_string_literal: true

namespace :gitlab do
  namespace :db do
    namespace :decomposition do
      desc 'Check if PostgreSQL max_connections needs to be increased'
      task connection_status: :environment do
        if Gitlab::Database.database_base_models.has_key?(:ci)
          puts "GitLab database already running on two connections"
          next
        end

        sql = <<~SQL
          select  q1.active, q2.max from
          (select count(*) as active from pg_stat_activity) q1,
          (select setting::int as max from pg_settings where name='max_connections') q2
        SQL

        active, max = ApplicationRecord.connection.select_one(sql).values

        puts "Currently using #{active} connections out of #{max} max_connections,"

        if active / max.to_f > 0.5
          puts <<~ADVISE_INCREASE
            which may run out when you switch to two database connections.

            Consider increasing PostgreSQL 'max_connections' setting.
            Depending on the installation method, there are different ways to
            increase that setting. Please consult the GitLab documentation.
          ADVISE_INCREASE
        else
          puts "which is enough for running GitLab using two database connections."
        end
      end
    end
  end
end
