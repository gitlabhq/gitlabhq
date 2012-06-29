module Grack
  class Auth < Rack::Auth::Basic

    def valid?
      true
    end
  end
end
