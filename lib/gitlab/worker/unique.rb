require 'digest'

module Gitlab
  module Worker
    module Unique
      def unique_processing(*args)
        key, timeout = uuid(args), 1.hour.to_i

        Gitlab::ExclusiveLease.new(key, timeout: timeout).tap do |lease|
          break unless lease.try_obtain

          begin
            yield
          rescue
            raise
          ensure
            lease.cancel!
          end
        end
      end

      private

      def uuid(args)
        Digest::SHA1.hexdigest(self.class.name + args.to_json)
      end
    end
  end
end
