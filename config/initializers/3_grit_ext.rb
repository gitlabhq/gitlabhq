require 'grit'
require 'pygments'

Grit::Git.git_timeout = Gitlab.config.git.timeout
Grit::Git.git_max_size = Gitlab.config.git.max_size

Grit::Blob.class_eval do
  include Linguist::BlobHelper
end
