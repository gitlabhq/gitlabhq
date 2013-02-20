module Gitlab
  VERSION = File.read(Rails.root.join("VERSION")).strip
  REVISION = `git log --pretty=format:'%h' -n 1`

  def self.config
    Settings
  end
end
