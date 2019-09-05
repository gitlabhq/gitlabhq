# frozen_string_literal: true

# Gitaly note: JV: no RPC's here.

module Gitlab
  module Git
    module Util
      LINE_SEP = "\n"

      def self.count_lines(string)
        case string[-1]
        when nil
          0
        when LINE_SEP
          string.count(LINE_SEP)
        else
          string.count(LINE_SEP) + 1
        end
      end
    end
  end
end
