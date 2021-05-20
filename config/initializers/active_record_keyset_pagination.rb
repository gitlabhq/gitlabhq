# frozen_string_literal: true

module PaginatorExtension
  # This method loads the records for the requested page and returns a keyset paginator object.
  def keyset_paginate(cursor: nil, per_page: 20)
    Gitlab::Pagination::Keyset::Paginator.new(scope: self.dup, cursor: cursor, per_page: per_page)
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Relation.include(PaginatorExtension)
end
