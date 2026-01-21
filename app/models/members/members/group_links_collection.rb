# frozen_string_literal: true

module Members
  class GroupLinksCollection < SimpleDelegator
    extend Forwardable

    def_delegators :@pagination_delegate, :total_count, :current_page, :limit_value

    def initialize(links, page: nil, total_count: nil, per_page: nil)
      @pagination_delegate = Gitlab::PaginationDelegate.new(
        page: page,
        per_page: per_page,
        count: total_count || links.count
      )
      super(links)
    end

    def project_links
      @project_links ||= select { |link| link.is_a?(ProjectGroupLink) }
    end

    def group_links
      @group_links ||= select { |link| link.is_a?(GroupGroupLink) }
    end
  end
end
