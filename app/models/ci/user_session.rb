module Ci
  class UserSession
    include ActiveModel::Conversion
    include Ci::StaticModel
    extend ActiveModel::Naming

    def authenticate(auth_opts)
      network = Ci::Network.new
      user = network.authenticate(auth_opts)

      if user
        user["access_token"] = auth_opts[:access_token]
        return Ci::User.new(user)
      else
        nil
      end

      user
    rescue
      nil
    end
  end
end
