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
