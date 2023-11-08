# frozen_string_literal: true

module QA
  module Runtime
    module Path
      class << self
        def qa_root
          ::File.expand_path('../../', __dir__)
        end

        def fixtures_path
          ::File.expand_path('../fixtures', __dir__)
        end

        def fixture(*args)
          ::File.join(fixtures_path, *args)
        end

        def qa_tmp(*args)
          ::File.join([qa_root, 'tmp', *args].compact)
        end
      end
    end
  end
end
