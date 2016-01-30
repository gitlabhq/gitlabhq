Haml::Template.options[:ugly] = true

# Remove the `:coffee` and `:coffeescript` filters
#
# See https://git.io/vztMu and http://stackoverflow.com/a/17571242/223897
Haml::Filters.remove_filter('coffee')
Haml::Filters.remove_filter('coffeescript')
