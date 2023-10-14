# frozen_string_literal: true

module Todos
  module Destroy
    class BaseService
      def execute
        raise NotImplementedError
      end
    end
  end
end
