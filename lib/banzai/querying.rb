# frozen_string_literal: true

module Banzai
  module Querying
    module_function

    # Searches a Nokogiri document using a CSS query, optionally optimizing it
    # whenever possible.
    #
    # document          - A document/element to search.
    # query             - The CSS query to use.
    # reference_options - A hash with nodes filter options
    #
    # Returns an array of Nokogiri::XML::Element objects if location is specified
    # in reference_options. Otherwise it would a Nokogiri::XML::NodeSet.
    def css(document, query, reference_options = {})
      # When using "a.foo" Nokogiri compiles this to "//a[...]" but
      # "descendant::a[...]" is quite a bit faster and achieves the same result.
      xpath = Nokogiri::CSS.xpath_for(query)[0].gsub(%r{^//}, 'descendant::')
      xpath = restrict_to_p_nodes_at_root(xpath) if filter_nodes_at_beginning?(reference_options)
      nodes = document.xpath(xpath)

      filter_nodes(nodes, reference_options)
    end

    def restrict_to_p_nodes_at_root(xpath)
      xpath.gsub('descendant::', './p/')
    end

    def filter_nodes(nodes, reference_options)
      if filter_nodes_at_beginning?(reference_options)
        filter_nodes_at_beginning(nodes)
      else
        nodes
      end
    end

    def filter_nodes_at_beginning?(reference_options)
      reference_options && reference_options[:location] == :beginning
    end

    # Selects child nodes if they are present in the beginning among other siblings.
    #
    # nodes - A Nokogiri::XML::NodeSet.
    #
    # Returns an array of Nokogiri::XML::Element objects.
    def filter_nodes_at_beginning(nodes)
      parents_and_nodes = nodes.group_by(&:parent)
      filtered_nodes = []

      parents_and_nodes.each do |parent, nodes|
        children = parent.children
        nodes    = nodes.to_a

        children.each do |child|
          next if child.text.blank?

          node = nodes.shift
          break unless node == child

          filtered_nodes << node
        end
      end

      filtered_nodes
    end
  end
end
