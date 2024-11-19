# frozen_string_literal: true

# We force require this to trigger the autoload and so that our monkeypatch will
# be applied in correct order, which is only after the class is loaded.
require 'fog/storage/google_json/requests/list_objects'

#
# Monkey patching the list_objects to support match_glob parameter
# See https://github.com/fog/fog-google/issues/614
#
module Fog
  module Storage
    class GoogleJSON
      class Real
        # This an identical copy of
        # https://github.com/fog/fog-google/blob/v1.19.0/lib/fog/storage/google_json/requests/list_objects.rb
        # with just match_glob added to the allowed_opts
        def list_objects(bucket, options = {})
          # rubocop: disable Style/PercentLiteralDelimiters -- this is an exact copy of the original method, just added match_glob here.
          allowed_opts = %i(
            delimiter
            match_glob
            max_results
            page_token
            prefix
            projection
            versions
          )
          # rubocop: enable Style/PercentLiteralDelimiters

          @storage_json.list_objects(
            bucket,
            **options.select { |k, _| allowed_opts.include? k }
          )
        end
      end
    end
  end
end

# We just need to add the match_glob attribute support here
module Fog
  module Storage
    class GoogleJSON
      class Files < Fog::Collection
        attribute :match_glob, aliases: "matchGlob"
      end
    end
  end
end
