module Gitlab
  Version = File.read(Rails.root.join("VERSION"))
  Revision = `git log --pretty=format:'%h' -n 1`

  def self.config
    Settings
  end
end
