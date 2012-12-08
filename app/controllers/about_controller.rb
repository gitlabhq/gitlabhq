class AboutController < ApplicationController
  def index

    # check Gitolite version
    gitolite_home = File.expand_path("~#{Gitlab.config.gitolite.ssh_user}")
    gitolite_version_file = "#{gitolite_home}/gitolite/src/VERSION"
    @gitolite_version = if File.exists?(gitolite_version_file) && File.readable?(gitolite_version_file)
                          File.read(gitolite_version_file)
                        end
    @gitolite_version ||= "unknown"

  end
end
