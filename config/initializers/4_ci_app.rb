module GitlabCi
  VERSION = Gitlab::VERSION
  REVISION = Gitlab::REVISION

  def self.config
    Settings
  end
end
