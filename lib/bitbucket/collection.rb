module Bitbucket
  class Collection < Enumerator
    def initialize(paginator)
      super() do |yielder|
        loop do
          paginator.items.each { |item| yielder << item }
        end
      end

      lazy
    end

    def method_missing(method, *args)
      return super unless self.respond_to?(method)

      self.send(method, *args) do |item|
        block_given? ? yield(item) : item
      end
    end
  end
end
