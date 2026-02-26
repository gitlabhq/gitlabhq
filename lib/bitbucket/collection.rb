# frozen_string_literal: true

module Bitbucket
  class Collection < Enumerator
    attr_reader :paginator

    delegate :page_info, to: :paginator

    def initialize(paginator)
      @paginator = paginator

      super() do |yielder|
        loop do
          paginator.items.each { |item| yielder << item }
        end
      end

      lazy
    end
  end
end
