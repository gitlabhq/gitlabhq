Rails.application.config.peek.adapter = :redis, { client: ::Redis.new(Gitlab::Redis.params) }

Peek.into Peek::Views::Host
Peek.into Peek::Views::PerformanceBar
Peek.into Gitlab::Database.mysql? ? Peek::Views::Mysql2 : Peek::Views::PG
Peek.into Peek::Views::Redis
Peek.into Peek::Views::Sidekiq
Peek.into Peek::Views::Rblineprof
Peek.into Peek::Views::GC
