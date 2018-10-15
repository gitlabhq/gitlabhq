# frozen_string_literal: true

module Peek
  module Views
    class Host < View
      def results
        {
          hostname: Gitlab::Environment.hostname,
          canary: Gitlab::Utils.to_boolean(ENV['CANARY'])
        }
      end
    end
  end
end
