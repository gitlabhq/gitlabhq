# frozen_string_literal: true

module QA
  module Runtime
    module Path
      extend self

      def qa_root
        ::File.expand_path('../../', __dir__)
      end
    end
  end
end
