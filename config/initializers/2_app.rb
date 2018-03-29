require_dependency 'gitlab/popen'

module Gitlab
  def self.config
    Settings
  end

  VERSION  = File.read(Rails.root.join("VERSION")).strip.freeze
  REVISION = Gitlab::Popen.popen(%W(#{config.git.bin_path} log --pretty=format:%h -n 1)).first.chomp.freeze
end
