# frozen_string_literal: true

direct :promo do |options = {}|
  uri = URI.parse("https://#{::Gitlab.promo_host}")

  uri.query = URI.encode_www_form(options[:query]) if options[:query]

  uri.path = options[:path] if options[:path]
  uri.fragment = options[:anchor] if options[:anchor]

  uri.to_s
end

direct :promo_pricing do |options = {}|
  options[:path] = "/pricing#{options[:path]}"
  promo_url(**options)
end
