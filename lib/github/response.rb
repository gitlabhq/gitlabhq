module Github
  class Response
    attr_reader :headers, :body, :status

    def initialize(headers, body, status)
      @headers = headers
      @body    = Oj.load(body, class_cache: false, mode: :compat)
      @status  = status
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
