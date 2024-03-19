# frozen_string_literal: true

module Gitlab
  module Auth
    class IpBlocked < StandardError
      def message
        _('Too many failed authentication attempts from this IP')
      end
    end
  end
end
