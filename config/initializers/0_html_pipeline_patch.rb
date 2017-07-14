module HTML
  class Pipeline
    class Filter
      # Searches a Nokogiri::HTML::DocumentFragment for text nodes. If no elements
      # are found, a second search without root tags is invoked.
      def search_text_nodes(doc)
        nodes = doc.xpath('.//text()')
        nodes.empty? ? doc.xpath('text()') : nodes
      end
    end
  end
end
