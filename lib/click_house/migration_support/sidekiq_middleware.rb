# frozen_string_literal: true

module ClickHouse
  module MigrationSupport
    class SidekiqMiddleware
      def call(worker, job, queue)
        return yield unless register_worker?(worker.class)

        ::ClickHouse::MigrationSupport::ExclusiveLock.register_running_worker(worker.class, worker_id(job, queue)) do
          yield
        end
      end

      private

      def worker_id(job, queue)
        [queue, job['jid']].join(':')
      end

      def register_worker?(worker_class)
        worker_class.respond_to?(:click_house_migration_lock) && worker_class.register_click_house_worker?
      end
    end
  end
end
