module Fog
  module Storage
    class GoogleXML
      class File < Fog::Model
        module MonkeyPatch
          # Monkey patch this to use `get_https_url`
          def url(expires)
            requires :key
            collection.get_https_url(key, expires)
          end
        end

        prepend MonkeyPatch
      end
    end
  end
end
