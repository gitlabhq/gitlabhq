require_dependency 'gitlab/popen'

module Gitlab
  def self.config
    Settings
  end

  REVISION = Gitlab::Popen.popen(%W(#{config.git.bin_path} log --pretty=format:%h -n 1)).first.chomp.freeze
end
