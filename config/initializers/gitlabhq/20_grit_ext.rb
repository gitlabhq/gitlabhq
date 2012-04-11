require 'grit'
require 'pygments'
require "utils"

Grit::Blob.class_eval do
  include Utils::FileHelper
  include Utils::Colorize
end

#monkey patch raw_object from string
Grit::GitRuby::Internal::RawObject.class_eval do
  def content
    @content
  end
end


Grit::Diff.class_eval do 
  def old_path
    Gitlabhq::Encode.utf8 a_path
  end

  def new_path
    Gitlabhq::Encode.utf8 b_path
  end
end

Grit::Git.git_timeout = GIT_OPTS["git_timeout"]
Grit::Git.git_max_size = GIT_OPTS["git_max_size"]
