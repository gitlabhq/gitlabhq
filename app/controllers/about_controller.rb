class AboutController < ApplicationController

  layout 'about'

  def index
    @contribution_guide = File.read(Rails.root.join("CONTRIBUTING.md"))
    @gitlab_version = "#{Gitlab::Version.squish}@#{Gitlab::Revision}"
    @gitolite_version = Gitlab::Gitolite.version
    @ruby_version = "#{RUBY_ENGINE}-#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
  end
end
