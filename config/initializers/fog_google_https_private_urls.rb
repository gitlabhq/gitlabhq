#
# Monkey patching the https support for private urls
# See https://gitlab.com/gitlab-org/gitlab-ee/issues/4879
#
module Fog
  module Storage
    class GoogleXML
      class File < Fog::Model
        module MonkeyPatch
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
