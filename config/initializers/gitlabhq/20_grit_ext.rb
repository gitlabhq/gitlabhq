require 'grit'
require 'pygments'
require "utils"

Grit::Blob.class_eval do
  include Utils::FileHelper
  include Utils::Colorize
end

Grit::Commit.class_eval do
  include CommitExt
end

Grit::Git.git_timeout = GIT_OPTS["git_timeout"]
Grit::Git.git_max_size = GIT_OPTS["git_max_size"]
