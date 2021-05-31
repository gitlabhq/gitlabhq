# frozen_string_literal: true

module Gitlab
  module Utils
    class Nokogiri
      class << self
        # Use Nokogiri to convert a css selector into an xpath selector.
        # Nokogiri can use css selectors with `doc.search()`.  However
        # for large node trees, it is _much_ slower than using xpath,
        # by several orders of magnitude.
        # https://gitlab.com/gitlab-org/gitlab/-/issues/329186
        def css_to_xpath(css)
          xpath = ::Nokogiri::CSS.xpath_for(css)

          # Due to https://github.com/sparklemotion/nokogiri/issues/572,
          # we remove the leading `//` and add `descendant-or-self::`
          # in order to ensure we're searching from this node and all
          # descendants.
          xpath.map { |t| "descendant-or-self::#{t[2..-1]}" }.join('|')
        end
      end
    end
  end
end
