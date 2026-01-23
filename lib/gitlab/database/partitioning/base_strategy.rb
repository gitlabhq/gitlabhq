# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class BaseStrategy
        protected

        def ensure_connection_set
          return unless model < SharedModel

          model.ensure_connection_set!
        end
      end
    end
  end
end
