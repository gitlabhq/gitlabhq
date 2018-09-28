module Gitlab
  module Git
    #
    # PreReceiveError is special because its message gets displayed to users
    # in the web UI. To prevent XSS we sanitize the message on
    # initialization.
    class PreReceiveError < StandardError
      def initialize(msg = '')
        super(nlbr(msg))
      end

      private

      # In gitaly-ruby we override this method to do nothing, so that
      # sanitization happens in gitlab-rails only.
      def nlbr(str)
        Gitlab::Utils.nlbr(str)
      end
    end
  end
end
