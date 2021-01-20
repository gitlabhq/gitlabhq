# frozen_string_literal: true

module Gitlab
  module Danger
    module TitleLinting
      DRAFT_REGEX = /\A*#{Regexp.union(/(?i)(\[WIP\]\s*|WIP:\s*|WIP$)/, /(?i)(\[draft\]|\(draft\)|draft:|draft\s\-\s|draft$)/)}+\s*/i.freeze

      module_function

      def sanitize_mr_title(title)
        remove_draft_flag(title).gsub(/`/, '\\\`')
      end

      def remove_draft_flag(title)
        title.gsub(DRAFT_REGEX, '')
      end

      def has_draft_flag?(title)
        DRAFT_REGEX.match?(title)
      end
    end
  end
end
