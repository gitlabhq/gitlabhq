require 'grit'
require 'pygments'

Grit::Git.git_timeout = Gitlab.config.git_timeout
Grit::Git.git_max_size = Gitlab.config.git_max_size

Grit::Blob.class_eval do
  include Linguist::BlobHelper

  def data
    @data ||= @repo.git.cat_file({:p => true}, id)
    Gitlab::Encode.utf8 @data
  end
end

Grit::Diff.class_eval do
  def old_path
    Gitlab::Encode.utf8 @a_path
  end

  def new_path
    Gitlab::Encode.utf8 @b_path
  end

  def diff
    Gitlab::Encode.utf8 @diff
  end
end
