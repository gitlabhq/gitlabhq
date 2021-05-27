# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # Module injected into ActiveRecord::Base to allow hijacking of the
      # "connection" method.
      module ActiveRecordProxy
        def connection
          LoadBalancing.proxy
        end
      end
    end
  end
end
