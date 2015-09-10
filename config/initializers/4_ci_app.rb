module GitlabCi
  VERSION = Gitlab::VERSION
  REVISION = Gitlab::REVISION
  
  REGISTRATION_TOKEN = SecureRandom.hex(10)

  def self.config
    Settings
  end
end
