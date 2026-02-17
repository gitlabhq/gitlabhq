# frozen_string_literal: true

module Issues
  class SearchData < ApplicationRecord
    self.table_name = 'issue_search_data'

    belongs_to :issue
  end
end
