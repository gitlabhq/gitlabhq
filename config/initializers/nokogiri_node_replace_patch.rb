# frozen_string_literal: true

# Applies the change from https://github.com/sparklemotion/nokogiri/pull/3568 to our Nokogiri.
# To be removed once that's merged and we can move it a version that includes it.
module NokogiriNodeReplacePatch
  def replace(node_or_tags)
    # Upstream handles these cases before the bug is hit.
    return super if parent.nil? || text?

    node_or_tags = parent.coerce(node_or_tags)
    # Upstream handles this case correctly too.
    return super unless node_or_tags.is_a?(Nokogiri::XML::NodeSet)

    reparented = Nokogiri::XML::NodeSet.new(document, node_or_tags.map { |n| add_previous_sibling(n) })
    unlink
    reparented
  end
end

Nokogiri::XML::Node.prepend(NokogiriNodeReplacePatch)
