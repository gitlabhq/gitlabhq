module OAuth2
  class Client
    def get_token(params, access_token_opts = {}, access_token_class = AccessToken)
      OpenStruct.new(token: "some_token")
    end
  end
end