# frozen_string_literal: true
module Gitlab
  module PhabricatorImport
    module Conduit
      class Pagination
        def initialize(cursor_json)
          @cursor_json = cursor_json
        end

        def has_next_page?
          next_page.present?
        end

        def next_page
          cursor_json["after"]
        end

        private

        attr_reader :cursor_json
      end
    end
  end
end
