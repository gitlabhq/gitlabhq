class Geo::OauthSession
  include ActiveModel::Model
  include HTTParty

  attr_accessor :state
  attr_accessor :return_to

  API_PREFIX = '/api/v3/'

  def is_oauth_state_valid?
    return true unless state
    salt, hmac, return_to = state.split(':', 3)

    return false unless return_to
    hmac == generate_oauth_hmac(salt, return_to)
  end

  def generate_oauth_state
    return unless return_to
    salt = generate_oauth_salt
    hmac = generate_oauth_hmac(salt, return_to)
    "#{salt}:#{hmac}:#{return_to}"
  end

  def get_oauth_state_return_to
    state.split(':', 3)[2] if state
  end

  def authenticate(access_token)
    opts = {
      query: access_token
    }
    endpoint = File.join(primary_node_url, API_PREFIX, 'user')
    response = self.class.get(endpoint, default_opts.merge(opts))

    build_response(response)
  end

  private

  def generate_oauth_salt
    SecureRandom.hex(16)
  end

  def generate_oauth_hmac(salt, return_to)
    return false unless return_to
    digest = OpenSSL::Digest.new('sha256')
    key = Gitlab::Application.secrets.secret_key_base + salt
    OpenSSL::HMAC.hexdigest(digest, key, return_to)
  end

  def primary_node_url
    Gitlab::Geo.primary_node.url
  end

  def default_opts
    {
      headers: { 'Content-Type' => 'application/json' },
    }
  end

  def build_response(response)
    case response.code
    when 200
      response.parsed_response
    when 401
      raise UnauthorizedError
    else
      nil
    end
  end
end
