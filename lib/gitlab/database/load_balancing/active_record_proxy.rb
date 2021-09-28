# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # Module injected into ActiveRecord::Base to allow hijacking of the
      # "connection" method.
      module ActiveRecordProxy
        def connection
          ::Gitlab::Database::LoadBalancing.proxy || super
        end
      end
    end
  end
end
