module Github
  class Response
    attr_reader :raw, :headers, :status

    def initialize(response)
      @raw     = response
      @headers = response.headers
      @status  = response.status
    end

    def body
      Oj.load(raw.body, class_cache: false, mode: :compat)
    end

    def rels
      links = headers['Link'].to_s.split(', ').map do |link|
        href, name = link.match(/<(.*?)>; rel="(\w+)"/).captures

        [name.to_sym, href]
      end

      Hash[*links.flatten]
    end
  end
end
