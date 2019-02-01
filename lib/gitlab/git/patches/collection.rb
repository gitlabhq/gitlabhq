# frozen_string_literal: true

module Gitlab
  module Git
    module Patches
      class Collection
        MAX_PATCH_SIZE = 2.megabytes

        def initialize(one_or_more_patches)
          @patches = Array(one_or_more_patches).map do |patch_content|
            Gitlab::Git::Patches::Patch.new(patch_content)
          end
        end

        def content
          @patches.map(&:content).join("\n")
        end

        def valid_size?
          size < MAX_PATCH_SIZE
        end

        # rubocop: disable CodeReuse/ActiveRecord
        # `@patches` is not an `ActiveRecord` relation, but an `Enumerable`
        # We're using sum from `ActiveSupport`
        def size
          @size ||= @patches.sum(&:size)
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
