module EE
  module Ci
    module Runner
      def tick_runner_queue
        ::Gitlab::Database::LoadBalancing::Sticking.stick(:runner, token)

        super
      end
    end
  end
end
