# frozen_string_literal: true

# Explicitly set the JSON adapter used by MultiJson
#
# This changes the default JSON adapter used by any gem dependencies
# we have that rely on MultiJson for their JSON handling. We set this
# to `oj` for a universal performance improvement in JSON handling
# across those gems.

MultiJson.use(:oj)
