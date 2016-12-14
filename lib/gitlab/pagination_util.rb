module Gitlab
  module PaginationUtil
    delegate :total_count,
             :total_pages,
             :current_page,
             :limit_value,
             :first_page?,
             :prev_page,
             :last_page?,
             :next_page, to: :pagination_delegate

    # requires a Gitlab::PaginationDelegate instance with the default configuration.
    # Example:
    #    @pagination_delegate ||= Gitlab::PaginationDelegate.new(page: 1,
    #                                                            per_page: 10,
    #                                                            count: 20)
    def pagination_delegate
      raise NotImplementedError.new("Expected #{self.class.name} to implement #{__method__}")
    end
  end
end
