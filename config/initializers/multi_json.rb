# frozen_string_literal: true

# Explicitly set the JSON adapter used by MultiJson
# Currently we want this to default to the existing json gem
MultiJson.use(:json_gem)
