require 'grit'
require 'pygments'

Grit::Git.git_timeout = GIT_OPTS["git_timeout"]
Grit::Git.git_max_size = GIT_OPTS["git_max_size"]

Grit::Blob.class_eval do
  include Linguist::BlobHelper

  def data
    @data ||= @repo.git.cat_file({:p => true}, id)
    Gitlab::Encode.utf8 @data
  end
end

Grit::Commit.class_eval do
  def to_hash
    {
      'id'       => id,
      'parents'  => parents.map { |p| { 'id' => p.id } },
      'tree'     => tree.id,
      'message'  => Gitlab::Encode.utf8(message),
      'author'   => {
        'name'  => Gitlab::Encode.utf8(author.name),
        'email' => author.email
      },
      'committer' => {
        'name'  => Gitlab::Encode.utf8(committer.name),
        'email' => committer.email
      },
      'authored_date'  => authored_date.xmlschema,
      'committed_date' => committed_date.xmlschema,
    }
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
