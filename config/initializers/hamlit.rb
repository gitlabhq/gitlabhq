# frozen_string_literal: true

Hamlit::RailsTemplate.set_options(attr_quote: '"')

Hamlit::Filters.remove_filter('coffee')
Hamlit::Filters.remove_filter('coffeescript')
