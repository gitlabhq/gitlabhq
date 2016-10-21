require 'digest'

module Gitlab
  module Worker
    class Unique
      def initialize(worker, *args)
        @worker = worker
        @args = args
      end

      def uuid
        @uuid ||= Digest::SHA1
          .hexdigest(@worker.name + @args.to_json)
      end

      def lease
        @lease ||= Gitlab::ExclusiveLease
          .new(uuid, timeout: 1.hour.to_i)
      end

      def schedule!
        if lease.try_obtain
          @worker.perform_async(*@args)
        end
      end

      def release!
        lease.cancel!
      end
    end
  end
end
