module Gitlab
  module GitalyClient
    class WikiFile
      ATTRS = %i(name mime_type path raw_data).freeze

      include AttributesBag
    end
  end
end
