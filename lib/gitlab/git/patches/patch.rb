# frozen_string_literal: true

module Gitlab
  module Git
    module Patches
      class Patch
        attr_reader :content

        def initialize(content)
          @content = content
        end

        def size
          content.bytesize
        end
      end
    end
  end
end
