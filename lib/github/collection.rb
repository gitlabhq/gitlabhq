module Github
  class Collection
    def initialize(url)
      @url = url
    end

    def fetch(query = {})
      return [] if @url.blank?

      Enumerator.new do |yielder|
        loop do
          response = client.get(@url, query)
          response.body.each { |item| yielder << item }
          raise StopIteration unless response.rels.key?(:next)
          @url = response.rels[:next]
        end
      end.lazy
    end

    private

    def client
      @client ||= Github::Client.new
    end
  end
end
