require 'fog/google'

# Hot patching the fog-google to enable
# https://github.com/fog/fog-aws/pull/431
#
# To be removed once the new version of fog-aws is released

module Fog
  module Storage
    class GoogleXML
      class Real
        def delete_object_url(bucket_name, object_name, expires)
          raise ArgumentError.new("bucket_name is required") unless bucket_name
          raise ArgumentError.new("object_name is required") unless object_name

          https_url({
                      headers: {},
                      host: @host,
                      method: "DELETE",
                      path: "#{bucket_name}/#{object_name}"
                    }, expires)
        end
      end
    end
  end
end
