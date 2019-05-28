# frozen_string_literal: true

module BitbucketServer
  class Collection < Enumerator
    attr_reader :paginator

    delegate :page_offset, :has_next_page?, to: :paginator

    def initialize(paginator)
      @paginator = paginator

      super() do |yielder|
        loop do
          paginator.items.each { |item| yielder << item }
        end
      end

      lazy
    end

    def current_page
      return 1 if page_offset <= 1

      [1, page_offset].max
    end

    def prev_page
      return unless current_page > 1

      current_page - 1
    end

    def next_page
      return unless has_next_page?

      current_page + 1
    end

    def method_missing(method, *args)
      return super unless self.respond_to?(method)

      self.__send__(method, *args) do |item| # rubocop:disable GitlabSecurity/PublicSend
        block_given? ? yield(item) : item
      end
    end
  end
end
