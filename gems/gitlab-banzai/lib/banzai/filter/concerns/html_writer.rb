# frozen_string_literal: true

module Banzai
  module Filter
    module Concerns
      module HtmlWriter
        extend ActiveSupport::Concern

        # Write an opening tag with the given tag name and attributes.
        #
        # The tag name and attribute names must not be user-specified; they are not validated.
        #
        # The attribute values are always escaped in the appropriate manner; the contract is that whatever value goes in
        # is the logical DOM value of the attribute that comes out.
        #
        # i.e.:
        #
        # ```ruby
        # html = write_opening_tag(tag, attrs)
        # doc = Nokogiri::HTML.fragment(html)
        # element = doc.child
        # expect(element.to_h).to match(attrs)
        # ```
        #
        # This function should *never be changed*.
        def write_opening_tag(tag_name, attributes)
          s = +"<" << tag_name
          attributes.each do |attr_name, attr_value|
            next if attr_value.nil?

            s << " " << attr_name << "="
            s << '"' << CGI.escapeHTML(attr_value.to_s) << '"'
          end
          s << ">"
        end

        # This is the most sure-fire correct way to implement the above function, relying on Nokogiri's DOM to correctly
        # serialise attributes for us.  Comparing the two with benchmark-ips and memory_profiler shows this method to be
        # 7x slower and adds 3x memory pressure compared to the above.  It is included here for reference.
        #
        # def write_opening_tag_nokogiri(tag_name, attributes)
        #   el = doc.document.create_element(tag_name, attributes.compact)
        #   el.to_html.chomp("</#{tag_name}>")
        # end
      end
    end
  end
end
