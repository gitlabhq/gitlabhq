module Gitlab
  module Diff
    module FileCollection
      def self.default_options
        ::Commit.max_diff_options.merge(ignore_whitespace_change: false, no_collapse: false)
      end
    end
  end
end
