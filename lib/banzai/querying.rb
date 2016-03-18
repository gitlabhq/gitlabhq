module Banzai
  module Querying
    # Searches a Nokogiri document using a CSS query, optionally optimizing it
    # whenever possible.
    #
    # document - A document/element to search.
    # query    - The CSS query to use.
    #
    # Returns a Nokogiri::XML::NodeSet.
    def self.css(document, query)
      # When using "a.foo" Nokogiri compiles this to "//a[...]" but
      # "descendant::a[...]" is quite a bit faster and achieves the same result.
      xpath = Nokogiri::CSS.xpath_for(query)[0].gsub(%r{^//}, 'descendant::')

      document.xpath(xpath)
    end
  end
end
