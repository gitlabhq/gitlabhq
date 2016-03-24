module Gollum
  GIT_ADAPTER = "rugged"
end
require "gollum-lib"

module Gollum
  class Committer
    # Patch for UTF-8 path
    def method_missing(name, *args)
      index.send(name, *args)
    end
  end
end
