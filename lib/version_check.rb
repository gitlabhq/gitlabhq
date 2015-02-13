# This class is used to encrypt GitLab version and URL
# with public key when we send it to version.gitlab.com to
# check if it is a new version for update
class VersionCheck
  include SimpleEncrypt

  def public_key
    public_key_file = Rails.root.join('safe', 'public.pem').to_s
    File.read(public_key_file)
  end

  def data
    {
      version: Gitlab::VERSION,
      url: Gitlab.config.gitlab.url
    }
  end

  def encrypt(string)
    encrypt_with_public_key(string, public_key)
  end

  def url
    "#{host}?gitlab_info=#{encrypt(data.to_json)}"
  end

  def host
    'http://localhost:9090/check.png'
  end
end
