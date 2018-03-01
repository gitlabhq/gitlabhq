require 'fog/aws'

# Hot patching the fog-aws to enable
# https://github.com/fog/fog-google/pull/306
#
# To be removed once the new version of fog-google is released

module Fog
  module Storage
    class AWS
      class Real
        def delete_object_url(bucket_name, object_name, expires, headers = {}, options = {})
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end

          unless object_name
            raise ArgumentError.new('object_name is required')
          end

          signed_url(options.merge({
                                     bucket_name: bucket_name,
                                     object_name: object_name,
                                     method: 'DELETE',
                                     headers: headers
                                   }), expires)
        end
      end
    end
  end
end
